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
// Created by Jason Leach on 2018-02-01.
//

import Foundation
import Alamofire

class KeycloakAPI {
    
    static let refreshTokenExpiredMessage = "Refresh token expired"
    
    class func exchange(oneTimeCode code: String, url: URL, grantType: String, redirectUri: String, clientId: String, completionHandler: @escaping (_ response: Credentials?, _ error: Error?) -> ()) {
        
        let params = ["grant_type": grantType, "redirect_uri": redirectUri, "client_id": clientId, "code": code]

        Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default)
            .responseJSON { response in

                guard response.result.isSuccess else {
                    completionHandler(nil, AuthenticationError.unknownError)
                    return
                }

                guard let json = response.result.value as? [String: Any] else {
                    print("No JSON returned in response.")
                    print("Error: \(String(describing: response.result.error))")

                    completionHandler(nil, AuthenticationError.unknownError)
                    return
                }

                let model = Credentials(withJSON: json)
                completionHandler(model, nil)
        }
    }
    
    class func refresh(credentials: Credentials, url: URL, grantType: String, redirectUri: String, clientId: String, completionHandler: @escaping (_ response: Credentials?, _ error: Error?) -> ()) {

        let params = ["grant_type": grantType, "redirect_uri": redirectUri, "client_id": clientId, "refresh_token": credentials.refreshToken]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.default)
            .responseJSON { response in
                
                guard response.result.isSuccess else {
                    completionHandler(nil, AuthenticationError.unknownError)
                    return
                }
                
                guard let json = response.result.value as? [String: Any], json["error"] == nil else {
                    print("result error: \(String(describing: response.result.error))")
                    if let json = response.result.value as? [String: Any] {
                        let errorMessage = String(describing: json["error_description"] ?? "No message supplied")
                        print("result message: \(errorMessage)")
                        
                        if errorMessage == KeycloakAPI.refreshTokenExpiredMessage {
                            completionHandler(nil, AuthenticationError.expired)
                            return
                        }
                    }

                    completionHandler(nil, AuthenticationError.unknownError)
                    return
                }
                
                let model = Credentials(withJSON: json)
                completionHandler(model, nil)
        }
    }
}
