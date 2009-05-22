require 'rake'

begin
  require 'spec/rake/spectask'

  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_opts = ["-f specdoc", "-c"]
    t.spec_files = FileList['spec/*_spec.rb']
  end

rescue LoadError
  desc 'Spec rake task not available'
  task :spec do
    abort 'Spec rake task is not available. Be sure to install rspec as a gem or plugin'
  end
end

begin
  require 'cucumber'
  require 'cucumber/rake/task'


  desc "Run Cucumber feature tests"
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format pretty" 
  end

rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end

begin
  require 'spec/rake/spectask'
  require 'cucumber'
  require 'cucumber/rake/task'
  require 'spec/rake/verify_rcov'

  task :test do
    Rake::Task[:spec].invoke
    Rake::Task[:features].invoke
  end

  desc "Run tests with RCov"
  namespace :rcov do
    rm "coverage.data" if File.exist?("coverage.data")

    desc "Run Features with RCov"
    Cucumber::Rake::Task.new(:features) do |t|
      t.rcov = true
      t.rcov_opts = %w{ --exclude osx\/objc,gems\/,spec\/,features\/ --aggregate coverage.data}
      t.rcov_opts << %[-o "coverage"]
    end

    Spec::Rake::SpecTask.new(:spec) do |t|
      t.spec_opts = ["-f specdoc", "-c"]
      t.spec_files = FileList['spec/*_spec.rb']
      t.rcov = true
      t.rcov_opts = %w{--exclude "spec/*,gems/*,features/*" --aggregate "coverage.data"}
    end

    desc "Run both specs and features to generate aggregated coverage"
    task :all do |t|
      Rake::Task["rcov:spec"].invoke
      Rake::Task["rcov:features"].invoke
    end

    RCov::VerifyTask.new(:verify => 'rcov:all') do |t|
      t.threshold = 100.0
      t.index_html = 'coverage/index.html'
    end
  end
rescue LoadError
  desc 'Rcov rake task not available'
  task :rcov do
    abort 'rcov rake task is not available. Be sure to install rspec, rcov and cucumber as a gem or plugin'
  end
end

task :default => [:test]