#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_vap.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_vap'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'Shaders/**/*'
  s.public_header_files = 'Classes/**/*.h', 'Shaders/**/*.h'
  s.dependency 'Flutter'
  # 更改为本地依赖方式
#  s.dependency 'QGVAPlayer', '= 1.0.19'
  s.dependency 'SDWebImage'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/../../td/flutter_vap-main/ios/Shaders"'
  }
end
