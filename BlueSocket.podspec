Pod::Spec.new do |s|
  s.name        = "BlueSocket"
  s.version     = "1.0.6"
  s.summary     = "Socket framework for Swift using the Swift Package Manager"
  s.homepage    = "https://github.com/IBM-Swift/BlueSocket"
  s.license     = { :type => "Apache License, Version 2.0" }
  s.author     = "IBM"
  s.module_name  = 'Socket'

  s.requires_arc = true
  s.osx.deployment_target = "10.11"
  s.ios.deployment_target = "10.0"
  s.tvos.deployment_target = "10.0"
  s.source   = { :git => "https://github.com/IBM-Swift/BlueSocket.git", :tag => s.version }
  s.source_files = "Sources/Socket/*.swift"
  s.pod_target_xcconfig =  {
        'SWIFT_VERSION' => '4.0.3',
  }
end
