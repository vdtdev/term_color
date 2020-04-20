require 'date'
version = File.read('./.version').strip
Gem::Specification.new do |s|
    s.name          = 'term_color'
    s.version       =  version
    s.date          = (Time.now.strftime('%Y-%m-%d'))
    s.summary       = "Terminal Colors"
    s.description   = <<-eof 
        Rule-based tool for easily applying color and styling to terminal text output.
    eof
    s.authors       = ["Wade H."]
    s.email         = 'vdtdev.prod@gmail.com'
    s.files         = [
        "lib/term_color.rb",
        "lib/term_color/rule.rb",
        "lib/term_color/rule_set.rb",
    ]
    s.required_ruby_version = '>= 2.6.1'
    s.files           << 'README.md'
    s.license       = 'MIT'
    s.homepage      = "https://github.com/vdtdev/term_color"
    s.metadata      = {
        "source_code_uri" => "https://github.com/vdtdev/term_color",
        "documentation_uri" => "https://rubydoc.info/gems/term_color/#{version}"
    }
    s.add_development_dependency 'rspec', '~> 3.7', '>= 3.7.0'
end