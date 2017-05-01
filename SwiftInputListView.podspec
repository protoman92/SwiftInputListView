Pod::Spec.new do |s|

    s.platform = :ios
    s.ios.deployment_target = '9.0'
    s.name = "SwiftInputListView"
    s.summary = "UICollectionView subclass that combines InputData and UIAdaptableInputView."
    s.requires_arc = true
    s.version = "1.1.9"
    s.license = { :type => "Apache-2.0", :file => "LICENSE" }
    s.author = { "Hai Pham" => "swiften.svc@gmail.com" }
    s.homepage = "https://github.com/protoman92/SwiftInputListView.git"
    s.source = { :git => "https://github.com/protoman92/SwiftInputListView.git", :tag => "#{s.version}"}
    s.framework = "UIKit"
    s.dependency 'SwiftInputView/Main'

    s.subspec 'Main' do |main|
        main.source_files = "SwiftInputListView/**/*.{swift}"
    end

    s.subspec 'Test' do |test|
        test.source_files = "SwiftInputListView/**/*.{swift}", "SwiftInputListViewTests/util/**/*.{swift}"
    end

end
