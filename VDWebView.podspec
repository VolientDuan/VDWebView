Pod::Spec.new do |s|
    s.name         = 'VDWebView'
    s.version      = '1.1.2'
    s.summary      = 'a great webView for iOS'
    s.homepage     = 'https://github.com/VolientDuan/VDWebView'
    s.license      = 'MIT'
    s.authors      = { 'volientDuan' => 'volientduan@163.com' }
    s.platform     = :ios, '8.0'
    s.framework = "UIKit"
    s.source       = { :git => 'https://github.com/VolientDuan/VDWebView.git', :tag => s.version }
    s.requires_arc = true
    s.source_files = 'VDWebView/VDWebView/**.{h,m}'
end
