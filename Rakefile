require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = %q{submodulesync}
    s.authors = ["Birkir A. Barkarson"]
    s.description = %q{GitHub post commit hook to update submodule pointers in containing projects}
    s.summary = s.description
    s.email = %q{birkirb@stoicviking.net}
    s.has_rdoc = true
    s.homepage = %q{http://github.com/birkirb/git_submodule_sync}
    s.rubyforge_project = %q{submodulesync}
    s.rubygems_version = %q{1.3.1}
    s.add_dependency(%q<sinatra>, [">= 0.9.1"])
    s.add_dependency(%q<birkirb-git>, [">= 1.3.0"])
    s.add_dependency(%q<rspec>, [">= 2"])
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available."
end

desc 'Start the commit monitor'
task 'start' do |t, args|
  ruby "-Ilib commit_monitor.rb"
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new('spec') do |t|
    t.rspec_opts = ["-fd", "-c"]
    t.ruby_opts = ["-Ispec,lib"]
    t.pattern = 'spec/**/*_spec.rb'
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

begin
  require 'metric_fu'

  MetricFu::Configuration.run do |config|
    #define which metrics you want to use
    config.metrics  = [:churn, :flog, :flay, :reek, :roodi]
    config.flay     = { :dirs_to_flay => ['app', 'lib']  } 
    config.flog     = { :dirs_to_flog => ['app', 'lib']  }
    config.reek     = { :dirs_to_reek => ['app', 'lib']  }
    config.roodi    = { :dirs_to_roodi => ['app', 'lib'] }
    config.saikuro  = { :output_directory => 'scratch_directory/saikuro', 
      :input_directory => ['app', 'lib'],
      :cyclo => "",
      :filter_cyclo => "0",
      :warn_cyclo => "5",
      :error_cyclo => "7",
      :formater => "text"} #this needs to be set to "text"
    config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
    config.rcov     = { :test_files => ['test/**/*_test.rb', 
      'spec/**/*_spec.rb'],
      :rcov_opts => ["--sort coverage", 
        "--no-html", 
        "--text-coverage",
        "--no-color",
        "--profile",
        "--rails",
        "--exclude /gems/,/Library/,spec"]}
  end

rescue LoadError
  # Too bad
end

task :default => [:spec, :features]
