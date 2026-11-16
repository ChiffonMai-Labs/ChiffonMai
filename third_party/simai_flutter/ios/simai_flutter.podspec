Pod::Spec.new do |s|
  s.name             = 'simai_flutter'
  s.version          = '0.5.0'
  s.summary          = 'Simai chart rendering and native MP4 export for Flutter.'
  s.description      = <<-DESC
Simai parser/player with Android MediaCodec and iOS VideoToolbox-backed video export.
                       DESC
  s.homepage         = 'https://github.com/Project-Fukakai/simai_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Project Fukakai' => 'opensource@project-fukakai.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'simai_flutter/Sources/simai_flutter/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.frameworks       = 'AVFoundation', 'VideoToolbox', 'Accelerate', 'Photos'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
