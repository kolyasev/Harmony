Pod::Spec.new do |s|
  s.name             = "Harmony"
  s.version          = "0.2.0"
  s.summary          = "Swift collections"
  s.homepage         = "https://github.com/kolyasev/Harmony"
  s.license          = 'MIT'
  s.author           = { "Denis Kolyasev" => "kolyasev@gmail.com" }
  s.source           = { :git => "https://github.com/kolyasev/Harmony.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Sources/**/*.swift'

  s.frameworks = 'Foundation'
  s.dependency 'SQLite.swift', '~> 0.11.5'
end
