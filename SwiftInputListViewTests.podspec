Pod::Spec.new do |s|

    s.platform = :ios
    s.ios.deployment_target = '9.0'
    s.name = "SwiftInputListViewTests"
    s.summary = "Mock input details for UIAdaptableInputListView unit tests."
    s.requires_arc = true
    s.version = "1.0.1"
    s.license = { :type => "Apache-2.0", :file => "LICENSE" }
    s.author = { "Hai Pham" => "swiften.svc@gmail.com" }
    s.homepage = "https://github.com/protoman92/SwiftInputListView.git"
    s.source = { :git => "https://github.com/protoman92/SwiftInputListView.git", :tag => "#{s.version}"}
    s.framework = "UIKit"
    s.dependency 'SwiftInputListView/Main'

    s.subspec 'Main' do |main|
        main.source_files = "SwiftInputListViewTests/util/**/*.{swift}"
    end

end
