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
import SwiftKeychainWrapper
import SwiftKeychainWrapper

public struct Credentials {
    
    public let accessToken: String
    internal let tokenType: String
    internal let refreshToken: String
    internal let sessionState: String
    internal let refreshExpiresIn: Int
    internal let refreshExpiresAt: Date
    internal let notBeforePolicy: Int
    internal let expiresIn: Int
    internal let expiresAt: Date
    internal let props: [String : Any]

    static func loadFromStoredCredentials() -> Credentials? {
        
        if let json = Credentials.load() {
            return Credentials(withJSON: json)
        }
        
        return nil
    }
    
    static func dateToString(date: Date) -> String {
        
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constants.Defaults.dateFormat
        formatter.timeZone = TimeZone(abbreviation: Constants.Defaults.timeZoneCode)

        return formatter.string(from: date)
    }
    
    static func toDate(string: String) -> Date? {
        
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constants.Defaults.dateFormat
        formatter.timeZone = TimeZone(abbreviation: Constants.Defaults.timeZoneCode)
        
        return formatter.date(from: string)
    }
    
    
    init(withJSON data: [String: Any]) {

        tokenType = data["token_type"] as! String
        refreshToken = data["refresh_token"] as! String
        accessToken = data["access_token"] as! String
        sessionState = data["session_state"] as! String
        refreshExpiresIn = data["refresh_expires_in"] as! Int   // in sec
        notBeforePolicy = data["not-before-policy"] as! Int
        expiresIn = data["expires_in"] as! Int                  // in sec
        
        // If we are loading credentials from the keychain we will have two additional fields representing when the
        // tokens will expire. Otherwise they need to be created
        if let refreshExpiresAtString  = data["refreshExpiresAt"] as? String, let refreshExpiresAt = Credentials.toDate(string: refreshExpiresAtString), let expiresAtString = data["expiresAt"] as? String, let expiresAt = Credentials.toDate(string: expiresAtString) {
            self.refreshExpiresAt = refreshExpiresAt
            self.expiresAt = expiresAt
        } else {
            refreshExpiresAt = Date().addingTimeInterval(Double(refreshExpiresIn))
            expiresAt = Date().addingTimeInterval(Double(expiresIn))
        }

        // Used to serialize this object so it can be stored in the keychian
        props = ["token_type": tokenType, "refresh_token": refreshToken, "access_token": accessToken, "session_state": sessionState, "refresh_expires_in": refreshExpiresIn, "not-before-policy": notBeforePolicy, "expires_in": expiresIn, "refreshExpiresAt": Credentials.dateToString(date: refreshExpiresAt), "expiresAt": Credentials.dateToString(date: expiresAt)]

        save()
    }

    internal func remove() {
        
        KeychainWrapper.standard.removeObject(forKey: Constants.Keychain.KeycloakCredentials)
    }
    
    public func isExpired() -> Bool {

        return isAuthTokenExpired() && isRefreshTokenExpired()
    }
    
    public func isAuthTokenExpired() -> Bool {
        
        return Date() > expiresAt
    }

    public func isRefreshTokenExpired() -> Bool {

        return Date() > refreshExpiresAt
    }

    private static func load() -> [String: Any]? {

        if let value = KeychainWrapper.standard.string(forKey: Constants.Keychain.KeycloakCredentials), let data = Data(base64Encoded: value) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            } catch let error {
                print("error converting to json: \(error)")
            }
        }

        return nil
    }
    
    private func save() {

        do {
            let data = try JSONSerialization.data(withJSONObject: props, options: .prettyPrinted)
            // Securley store the credentials
            guard KeychainWrapper.standard.set(data.base64EncodedString(), forKey: Constants.Keychain.KeycloakCredentials) else {
                fatalError("Unalbe to store auth credentials")
            }
        } catch let error {
            print("error converting to json: \(error)")
        }
    }
    
}
