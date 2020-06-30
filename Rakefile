# Rakefile for Image Filter DSL
require 'yard'
require 'fileutils'
require 'rubygems/package_task'
require 'date'

# YARD Doc Directory
DOC_DIR = File.join('.','doc')
# Gem version from TermColor module
GEM_VERSION = Gem::Version.new((Proc.new{ load('./lib/term_color.rb'); TermColor::VERSION }).call)

# ====[ Methods ]====

##
# Generate YARD doc build task placing current version in title
def create_yard_task
    begin
        Rake::Task['build_doc'].clear
    rescue
        #
    end
    # desc "Generate documentation using YARD"
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
    Rake::Task['build_doc'].comment = "Generate documentation using YARD"
end

##
# Create gem build tasks, setting gem version to match the VERSION
# constant defined in the TermColor module
def create_gem_tasks
    spec = Gem::Specification.load('./term_color.gemspec')
    Gem::PackageTask.new(spec) {|pkg|}
end


# ====[Tasks]====

create_yard_task
create_gem_tasks

desc "Batch: Clean + build docs, and build gem"
task :batch_build do
    print ">> (1) Cleaning doc dir..\n"
    Rake::Task["clean_doc"].invoke
    print ">> (2) Building docs..\n"
    Rake::Task["build_doc"].invoke
    print ">> (3) Building gem..\n"
    Rake::Task["gem"].invoke
    print "Finished all 3 steps\n"
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