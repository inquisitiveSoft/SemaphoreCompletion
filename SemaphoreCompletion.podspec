#
# Be sure to run `pod lib lint SemaphoreCompletion.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SemaphoreCompletion"
  s.version          = "0.1.2"
  s.summary          = "SemaphoreCompletion"
  s.description      = <<-DESC
    SYMLSemaphoreCompletion performs a completion block when a group of tasks have finished. It's conceptually similar to XCTest's expectations.
                       DESC
  s.homepage         = "https://github.com/inquisitivesoft/SemaphoreCompletion"
  s.license          = 'MIT'
  s.author           = { "Harry Jordan" => "harry@inquisitivesoftware.com" }
  s.source           = { :git => "https://github.com/inquisitivesoft/SemaphoreCompletion.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/inquisitivesoft'

  s.platform     = :ios, '7.0'
  s.requires_arc = true
	
  s.source_files = 'Classes/*.{m,h}'
  s.public_header_files = 'Classes/**/*.h'
end
