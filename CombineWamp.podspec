Pod::Spec.new do |s|
    s.name             = 'CombineWamp'
    s.version          = '0.1.2'
    s.summary          = 'WAMP protocol (https://wamp-proto.org) implemented using iOS 13 WebSocket and Combine'
  
    s.homepage         = 'https://github.com/FastSkipper-com/CombineWamp.git'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'pavelko3lo' => 'pavelko3lo@gmail.com' }
    s.source           = { :git => 'https://github.com/FastSkipper-com/CombineWamp.git', :tag => s.version.to_s }
  
    s.ios.deployment_target = '13.0'
    s.source_files = 'Sources/**/*'
    s.swift_version = '5.0'

    s.dependency 'FoundationExtensions'
    s.dependency 'CombineWebSocket'
  end