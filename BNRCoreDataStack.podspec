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
  s.version      = "1.3.0"
  s.summary      = "The Big Nerd Ranch Core Data stack."

  s.description  = <<-DESC
The BNR Core Data stack provides what we consider best practices for using
Core Data in our applications.

It takes the place of the boilerplate setup code from Xcode's template and
focuses on efficient performance and change management.
DESC

  s.homepage     = "https://github.com/bignerdranch/CoreDataStack"
  s.license      = "MIT"

  s.authors              = ["Robert Edwards", "John Gallagher", "Brian Hardy", "Zachary Waldowski"]

  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"


  s.source       = { :git => "https://github.com/bignerdranch/CoreDataStack.git", :tag => "v#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "Sources"

  s.frameworks = "CoreData"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '2.3' }

end
