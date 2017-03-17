Pod::Spec.new do |s|
  s.name        = "BlueSocket"
  s.version     = "0.12.34-beta"
  s.summary     = "Socket framework for Swift using the Swift Package Manager"
  s.homepage    = "https://github.com/IBM-Swift/BlueSocket"
  s.license     = { :type => "Apache License, Version 2.0" }
  s.author     = "IBM"

  s.requires_arc = true
  s.osx.deployment_target = "10.11"
  s.ios.deployment_target = "10.0"
  s.source   = { :git => "https://github.com/IBM-Swift/BlueSocket.git", :tag => s.version }
  s.source_files = "Sources/*.swift"
  s.pod_target_xcconfig =  {
        'SWIFT_VERSION' => '3.0',
  }
end