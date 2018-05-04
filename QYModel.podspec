Pod::Spec.new do |s|  
  s.name             = "QYModel"  
  s.version          = "1.0.0"  
  s.summary          = "Magical Data Modelling Framework for JSON. Create rapidly powerful, atomic and smart data model classes."  
 
  s.homepage         = "https://github.com/peanutNote"   
  s.license          = 'MIT'  
  s.author           = { "peanutNote" => "422794901@qq.com" }  
  s.source           = { :git => "https://github.com/peanutNote/CCModel.git", :tag => s.version.to_s }  
  
  s.platform     = :ios, '7.0'  
  # s.ios.deployment_target = '5.0'  
  # s.osx.deployment_target = '10.7'  
  s.requires_arc = true  
  
  s.source_files = 'QYModel/*'  
  # s.resources = 'Assets'  
  
  # s.ios.exclude_files = 'Classes/osx'  
  # s.osx.exclude_files = 'Classes/ios'  
  # s.public_header_files = 'Classes/**/*.h'  
  
end
