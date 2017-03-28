Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "QMobileUI"
  s.version      = "0.0.1"
  s.summary      = "A short description of QMobileUI."

  s.description  = <<-DESC
                   Present records
                   DESC

  s.homepage     = "http://git.4d.com/QMobileUI"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license      = "Copyright © 4D"

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author             = { "Eric Marchand" => "eric.marchand@4d.com" }

  s.ios.deployment_target = "10.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "http://git.4d.com/QMobileUI.git", :tag => "#{s.version}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "Sources/**/*.swift"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.dependency "XCGLogger"
  s.dependency "QMobileDataStore"

end
