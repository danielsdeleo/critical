require 'spec/rake/spectask'

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['-cfs']
  t.spec_files = FileList['spec/**/*_spec.rb']
end

task :default => :spec