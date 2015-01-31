Pod::Spec.new do |s|
  s.name = 'SwiftSocketIO'
  s.version = '0.1.0'
  s.license = 'MIT'
  s.summary = 'Socket.IO client in Swift'
  s.homepage = 'https://github.com/adamrothman/SwiftSocketIO'
  s.authors = { 'Adam Rothman' => 'rothman.adam@gmail.com' }
  s.source = { :git => 'https://github.com/adamrothman/SwiftSocketIO.git', :tag => s.version }

  s.ios.deployment_target = '8.1'
  s.osx.deployment_target = '10.10'

  s.source_files = 'SwiftSocketIO/*.swift'

  s.requires_arc = true

  s.dependency 'Alamofire', '~> 1.1'
  s.dependency 'SocketRocket', '~> 0.3.1-beta2'
end
