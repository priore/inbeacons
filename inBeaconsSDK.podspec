Pod::Spec.new do |s|
  s.name         	= 'inBeaconsSDK'
  s.version      	= '1.0.0'
  s.platform        = :ios, '7.1'
  s.summary      	= 'inBeaconsSDK using Estimote beacons'
  s.description		= 'Makes really easy to use Estimote beacons from inBeacons cloud CMS (www.inbeacons.com)'
  s.homepage     	= 'http://www.inbeacons.com'
  s.social_media_url	= 'https://twitter.com/danilopriore'
  s.license      	= { :type => 'GNU License', :file => 'LICENSE' }
  s.author       	= { 'Danilo Priore' => 'support@prioregroup.com' }
  s.source 			= { git: 'https://github.com/priore/inbeacons.git', :tag => "v#{s.version}" }
  s.source_files 	= 'inBeaconsSDK/inbeacons.{h,m}'
  s.ios.framework	= 'CoreLocation','UIKit'
  s.requires_arc 	= true
end
