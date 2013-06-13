Pod::Spec.new do |s|
  s.name          = 'DownloadManager'
  s.version       = '2.0'
  s.platform      = :ios, '5.0'
  s.summary       = 'Download Manager for iOS'
  s.homepage      = 'http://www.toodev.com'
  s.author        = "Daniele Poggi"
  s.source        = { :git  => 'git@github.com:toodev/DownloadManager.git' }
  s.license       = { :type => 'Public',
                      :text => %Q|All rights reserved| }
  s.source_files = '*.{h,m}'
  s.dependency 'ASIHTTPRequest'
  s.dependency 'ZipArchive'
  s.requires_arc = false

end
