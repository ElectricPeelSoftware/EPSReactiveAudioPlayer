Pod::Spec.new do |s|
  s.name             = "EPSReactiveAudioPlayer"
  s.version          = "0.2.1"
  s.summary          = "A view model which manages an AVPlayer object."

  s.homepage         = "https://github.com/ElectricPeelSoftware/EPSReactiveAudioPlayer"
  s.license          = 'MIT'
  s.author           = { "Peter Stuart" => "peter@electricpeelsoftware.com" }
  s.source           = { :git => "https://github.com/ElectricPeelSoftware/EPSReactiveAudioPlayer.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Classes'

  s.public_header_files = 'Classes/*.h'
  s.dependency 'ReactiveCocoa', '~> 2.3'
end
