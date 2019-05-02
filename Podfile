
target 'mbBooks' do
    # Uncomment the next line to define a global platform for your project
    platform :osx, '10.14'
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod 'SSZipArchive'
    #pod 'KissXML'
    pod 'KFToolbar'#,    :git => 'https://kfi.codebasehq.com/kftoolbar/kftoolbar.git'
end

target 'mbBooks iOS' do
    platform :ios, '5.1'
    pod 'SSZipArchive'
    #pod 'KissXML'
end

target 'mbBooks Tests' do
    inherit! :search_paths
    platform :osx, '10.14'
    pod 'SSZipArchive'
    #pod 'KissXML'
    pod 'OCMock'
end
