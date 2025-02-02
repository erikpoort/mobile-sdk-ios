Pod::Spec.new do |s|

  s.name         = "AppNexusSDK"
  s.version      = "7.16.0"
  s.platform     = :ios, "9.0"

  s.summary      = "AppNexus iOS Mobile Advertising SDK"
  s.description  = <<-DESC
Our mobile advertising SDK gives developers a fast and convenient way to monetize their apps.
DESC

  s.homepage     = "https://github.com/appnexus/mobile-sdk-ios"
  s.source       = { :git => "https://github.com/appnexus/mobile-sdk-ios.git", :tag => "#{s.version}" }
  s.author       = { "AppNexus Mobile Engineering" => "sdk@appnexus.com" }
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.requires_arc = true
  s.static_framework = true
  s.default_subspec = 'AppNexusSDK'

  s.subspec 'AppNexusSDK' do |subspec|
    subspec.source_files         = "sdk/sourcefiles/**/*.{h,m}"
    subspec.public_header_files  = "sdk/sourcefiles/public-headers/*.h"
    subspec.resources            = "sdk/sourcefiles/**/*.{png,bundle,xib,nib,js,html,strings}","sdk/AppNexusSDK/SDK-Info.plist"   
    subspec.vendored_frameworks   =  "sdk/sourcefiles/Viewability/OMSDK_Appnexus.xcframework"
    subspec.frameworks           = 'WebKit'
    subspec.pod_target_xcconfig = { "VALID_ARCHS[sdk=iphoneos*]": "arm64 armv7", "VALID_ARCHS[sdk=iphonesimulator*]": "x86_64 arm64" }


  end

  s.subspec 'GoogleAdapter' do |subspec|
    subspec.dependency  'AppNexusSDK/AppNexusSDK', "#{s.version}"
    subspec.dependency  'Google-Mobile-Ads-SDK', '8.5.0'
    subspec.source_files         = "mediation/mediatedviews/GoogleAdMob/*.{h,m}"
    subspec.public_header_files  = "mediation/mediatedviews/GoogleAdMob/ANAdAdapterNativeAdMob.h"
    subspec.xcconfig              = { 'FRAMEWORK_SEARCH_PATHS' => '${PODS_ROOT}/Google-Mobile-Ads-SDK/**' }
  end

  s.subspec 'FacebookCSRAdapter' do |subspec|
    subspec.dependency  'AppNexusSDK/AppNexusSDK', "#{s.version}"
    subspec.dependency 'FBAudienceNetwork', '6.5.0'
    subspec.source_files         = "csr/Facebook/*.{h,m}"
    subspec.public_header_files  = "csr/Facebook/*.h"
    subspec.xcconfig              = { 'FRAMEWORK_SEARCH_PATHS' => '${PODS_ROOT}/FBAudienceNetwork/**' }
  end 

  s.subspec 'FacebookAdapter' do |subspec|
    subspec.dependency  'AppNexusSDK/AppNexusSDK', "#{s.version}"
    subspec.dependency 'FBAudienceNetwork', '6.5.0'
    subspec.source_files         = "mediation/mediatedviews/Facebook/*.{h,m}"
    subspec.public_header_files  = "mediation/mediatedviews/Facebook/ANAdAdapterNativeFacebook.h"
    subspec.xcconfig              = { 'FRAMEWORK_SEARCH_PATHS' => '${PODS_ROOT}/FBAudienceNetwork/**' }
  end 

  s.subspec 'SmartAdAdapter' do |subspec|
    subspec.dependency 'AppNexusSDK/AppNexusSDK', "#{s.version}"
    subspec.source_files = "mediation/mediatedviews/SmartAd/*.{h,m}"
    subspec.public_header_files = "mediation/mediatedviews/SmartAd/ANAdAdapterSmartAdBase.h"
    subspec.dependency 'Smart-Display-SDK', '7.10.1'
    subspec.xcconfig              = { 'FRAMEWORK_SEARCH_PATHS' => '${PODS_ROOT}/Smart-Display-SDK/**' }
  end

end
