#
#  Be sure to run `pod spec lint BNRCoreDataStack.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "BNRCoreDataStack"
  s.version      = "0.3.0b1"
  s.summary      = "The Big Nerd Ranch Core Data stack."

  s.description  = <<-DESC
The BNR Core Data stack provides what we consider best practices for using
Core Data in our applications.

It takes the place of the boilerplate setup code from Xcode's template and
focuses on efficient performance and change management.
DESC

  s.homepage     = "https://github.com/bignerdranch/CoreDataStack"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  s.authors              = ["Robert Edwards", "Brian Hardy"]
  # Or just: s.author    = "Brian Hardy"
  # s.authors            = { "Brian Hardy" => "brian@bignerdranch.com" }
  # s.social_media_url   = "http://twitter.com/Brian Hardy"

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"


  s.source       = { :git => "git@github.com:bignerdranch/CoreDataStack.git", :tag => "v0.3.0b1" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "CoreDataStack"

  s.public_header_files = "CoreDataStack/*.h"


  s.frameworks = "CoreData"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
