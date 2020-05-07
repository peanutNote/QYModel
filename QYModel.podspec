Pod::Spec.new do |s|  
  s.name             = "QYModel"  
  s.version          = "1.0.1"  
  s.summary          = "Magical Data Modelling Framework for JSON. Create rapidly powerful, atomic and smart data model classes."  
 
  s.homepage         = "https://github.com/peanutNote"   
  s.license          = 'MIT'  
  s.author           = { "peanutNote" => "422794901@qq.com" }  
  s.source           = { :git => "https://github.com/peanutNote/QYModel.git", :tag => s.version.to_s }  
  
  s.platform     = :ios, '7.0'  
  s.requires_arc = true  
  s.source_files = 'QYModel/QYModel/**/*.{h,m}'  
  
end
