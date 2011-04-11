
require 'rubygems'
require 'rake/gempackagetask'

$LOAD_PATH.unshift('lib')
require 'epo'

spec = Gem::Specification.new do |s|

        s.name = 'epo'
        s.rubyforge_project = 'epo'
        s.version = EPO::VERSION
        s.author = EPO::AUTHORS.first
        s.homepage = EPO::WEBSITE
        s.summary = "A no-brainer, plain-ruby database"
        s.email = "crapooze@gmail.com"
        s.platform = Gem::Platform::RUBY

        s.files = [
          'Rakefile', 
          'TODO', 
          'README', 
          'lib/epo.rb',
          'lib/epo/core/db.rb',
          'lib/epo/core/observer.rb',
        ]

        s.require_path = 'lib'
        s.bindir = 'bin'
        s.executables = []
        s.has_rdoc = true

        s.add_dependency('derailleur', '>= 0.0.6')
        s.add_dependency('welo', '>= 0.1.1')
end

Rake::GemPackageTask.new(spec) do |pkg|
        pkg.need_tar = true
end

task :gem => ["pkg/#{spec.name}-#{spec.version}.gem"] do
        puts "generated #{spec.version}"
end
