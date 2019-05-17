source 'https://github.com/CocoaPods/Specs.git'

project 'SecureImage.xcodeproj'
platform :ios, '9.0'
use_frameworks!

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = "-"
        config.build_settings['EXPANDED_CODE_SIGN_IDENTITY_NAME'] = "-"
        config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
        config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      end
    end
end

target 'SecureImage' do
#    pod 'SingleSignOn', :path => '../sso-ios'
    pod 'SingleSignOn', :git => 'https://github.com/bcgov/mobile-authentication-ios.git', :tag => 'v1.0.4'
    pod 'RealmSwift'
    pod 'SwiftKeychainWrapper'
    pod 'Alamofire'
end

target 'SecureImageTests' do
    pod 'RealmSwift'
    pod 'SwiftKeychainWrapper'
    pod 'Alamofire'
end
