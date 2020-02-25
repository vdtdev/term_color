version = '0.0.1'
Gem::Specification.new do |s|
    s.name          = 'term_color'
    s.version       =  version
    s.date          = '2020-02-25'
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
    s.files           << 'README.md'
    s.license       = 'MIT'
    s.homepage      = "https://github.com/vdtdev/term_color"
    s.metadata      = {
        "source_code_uri" => "https://github.com/vdtdev/term_color"
        # "documentation_uri" => "https://rubydoc.info/gems/image_filter_dsl/#{version}"
    }
    s.add_development_dependency 'rspec', '~> 3.7', '>= 3.7.0'
end