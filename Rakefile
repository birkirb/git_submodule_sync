require 'rake'

require 'spec/rake/spectask'

desc "Run all examples with RCov"

Spec::Rake::SpecTask.new('spec_with_rcov') do |t|

  t.spec_files = FileList['spec/*_spec.rb']

  t.rcov = true

end
