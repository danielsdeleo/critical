require 'spec/rake/spectask'

ROOT = File.expand_path(File.dirname(__FILE__))

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{ROOT}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

task :default => :spec