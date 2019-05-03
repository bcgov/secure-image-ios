//
// SecureImage
//
// Copyright © 2018 Province of British Columbia
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at 
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Created by Jason Leach on 2018-01-30.
//

import UIKit
import WebKit

public class AuthViewController: UIViewController {

    private var authUrl: URL
    private var redirectUri: String
    private var clientId: String
    private var responseType: String
    private var idpHint: String?
    private let headerViewHeight: CGFloat = {
        return 88.0
    }()
    private let webView: WKWebView = {
        let wv = WKWebView()
        wv.translatesAutoresizingMaskIntoConstraints = false

        return wv
    }()
    private let headerView: WebHeaderView = {
        let bundle = Bundle(for: WebHeaderView.self)
        let v = bundle.loadNibNamed("WebHeaderView", owner: self, options: nil)?.first as! WebHeaderView
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()
    private var recievedCustomRedirectUrl = false
    public weak var delegate: AuthenticationDelegate?
    
    public init(authUrl: URL, redirectUri: String, clientId: String, responseType: String, idpHint: String? = nil) {
     
        self.redirectUri = redirectUri
        self.clientId = clientId
        self.authUrl = authUrl
        self.responseType = responseType
        self.idpHint = idpHint

        super.init(nibName: nil, bundle: nil)
        
        webView.navigationDelegate = self
        
        loadAuthenticationPage()
    }
    
    required public init?(coder aDecoder: NSCoder) {

        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {

        super.viewDidLoad()

        commonInit()
    }
    
    private func commonInit() {
        
        // NSCoding support was broken in WKWebView prior to 11.0; must be
        // added programatically.
        
        headerView.onCloseTouched = {
            
            self.dismiss(animated: true, completion: nil)
        }
        
        view.addSubview(headerView)
        view.addSubview(webView)
        
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: headerViewHeight).isActive = true

        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func buildAuthenticationURL() -> URL? {
        
        var components = URLComponents(url: authUrl, resolvingAgainstBaseURL: true)
        var query = "response_type=\(responseType)&client_id=\(clientId)&redirect_uri=\(redirectUri)"
        if let idpHint = idpHint {
            query = query + "&kc_idp_hint=\(idpHint)"
        }

        components?.query = query

        return components?.url
    }
    
    private func loadAuthenticationPage() {
        
        let myURL = buildAuthenticationURL()
        let myRequest = URLRequest(url: myURL!)
        
        webView.load(myRequest)

        headerView.url = myURL
    }
    
    private func extractCode(from url: URL) -> String? {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let items = components.queryItems else {
            return nil
        }
        
        let code = items.filter {  $0.name == responseType }
        if code.count > 0 {
            return code.first!.value
        }

        return nil
    }
    
    private func handelCustomRedirect(url: URL) {
        
        guard let code = extractCode(from: url) else {
            delegate?.authenticationFailed(error: AuthenticationError.unableToExtractOneTimeCode)
            return
        }

        self.delegate?.authenticationSucceded(oneTimeCode: code)

        self.dismiss(animated: true, completion: nil)
    }

    private func isCustomRedirect(url: URL) -> Bool {
        
        // Only the scheme is important in determining if the URL is our
        // custom redirect URL.
        let redirComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let customComponents = URLComponents(string: redirectUri)
        
        return redirComponents?.scheme == customComponents?.scheme
    }
    
    private func canLoad(url: URL) -> Bool {
        return true;

        // We only load URLs from our authorization host.
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host else {
            return false
        }

        return host.range(of: Constants.API.allowedWebDomain) != nil
    }
}

// MARK: WKNavigationDelegate
extension AuthViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        guard let url = navigationResponse.response.url else {
            
            decisionHandler(.cancel)
            return
        }

        decisionHandler(canLoad(url: url) ? .allow : .cancel)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if isCustomRedirect(url: url) {
            // We have intercepted our custom redirect URL
            recievedCustomRedirectUrl = true
            handelCustomRedirect(url: url)
            decisionHandler(.cancel)

            return
        }
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {

        if (recievedCustomRedirectUrl) {
            return
        }
        
        delegate?.authenticationFailed(error: AuthenticationError.webRequestFailed(error: error))
        dismiss(animated: true, completion: nil)

        print("failed web navigation = \(error)")
    }
}
