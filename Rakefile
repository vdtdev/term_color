# Rakefile for Image Filter DSL
require 'yard'
require 'fileutils'
require 'rubygems/package_task'
require 'date'


DOC_DIR = File.join('.','doc')
GEM_VERSION = File.read('./.version').strip
#=--prep gem spec--
spec = Gem::Specification.load('./term_color.gemspec')

desc "Generate documentation using YARD"
YARD::Rake::YardocTask.new(:build_doc) do |y|
    y.options = [
        ["--title", "Term Color v#{GEM_VERSION}"],
        '--protected', 
        ['--markup', 'markdown'],
        ['--asset', './docs'],
        ['--output-dir',DOC_DIR]
    ]
    y.files = [
        'lib/**/*.rb'#,
        # '-',
        # 'CHANGELOG.md'
    ]
end

desc "Clean generated documentation directory"
task :clean_doc do
    if Dir.exist?(DOC_DIR)
        FileUtils.remove_dir(DOC_DIR,true)
        print "Doc directory removed\n"
    else
        print "Doc directory doesn't exist-- skipping\n"
    end
end

desc "Build gem"
Gem::PackageTask.new(spec) do |pkg|
end