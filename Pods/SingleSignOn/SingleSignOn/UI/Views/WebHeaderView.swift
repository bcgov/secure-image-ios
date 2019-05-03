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
// Created by Jason Leach on 2018-01-31.
//

import UIKit

typealias WebHeaderViewCloseCallback = (() -> Void)

class WebHeaderView: UIView {

    @IBOutlet weak private var securityIndicatorImageView: UIImageView!
    @IBOutlet weak private var hostLabel: UILabel!
    
    private let lockImage: UIImage? = {
        return UIImage(named: "lock", in: Bundle(for: WebHeaderView.self), compatibleWith: nil)
    }()
    private let unlockImage: UIImage? = {
        return UIImage(named: "unlock", in: Bundle(for: WebHeaderView.self), compatibleWith: nil)
    }()
    internal var onCloseTouched: WebHeaderViewCloseCallback?
    internal var url: URL? {
        didSet {
            guard let value = url, let components = URLComponents(url: value, resolvingAgainstBaseURL: true) else {
                return
            }
            
            if let scheme = components.scheme, let host = components.host {
                updateSecurityIndicator(scheme: scheme)
                updateHostLabel(scheme: scheme, host: host)
            }
        }
    }
    
    override func awakeFromNib() {

        super.awakeFromNib()

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
    }

    private func commonInit() {

        backgroundColor = Theme.governmentDarkBlue
    }
    
    private func isSecureScheme(schem: String) -> Bool {
        
        return schem == Constants.API.secureScheme
    }
    
    private func updateSecurityIndicator(scheme: String) {
        
        if isSecureScheme(schem: scheme) {
            securityIndicatorImageView.image = lockImage
        } else {
            securityIndicatorImageView.image = unlockImage
        }
    }
    
    private func updateHostLabel(scheme: String, host: String) {
        
        let aScheme = "\(scheme)://"
        let attributedSchem = NSMutableAttributedString.init(string: aScheme)
        let range1 = (aScheme as NSString).range(of: aScheme)
        attributedSchem.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.lightGray , range: range1)
        
        let attributedHost = NSMutableAttributedString.init(string: host)
        let range2 = (host as NSString).range(of: host)
        attributedHost.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.white , range: range2)

        attributedSchem.append(attributedHost)
        
        hostLabel.attributedText = attributedSchem
    }

    @IBAction private func closeButtonTouched(sender: UIButton) {
        
        onCloseTouched?()
    }
}
