Before do
  require 'spec/spec_helper'
  ::LOCAL_REPOS = File.join(`pwd`.chomp, 'spec/files/test_repos')
  initalize_repos
  @commitish = update_submodule.sha
end

After do
  FileUtils.rm_r(LOCAL_REPOS) if File.exists?(LOCAL_REPOS)
end

World do
  session = Webrat::SinatraSession.new(Sinatra::Application)
  session.extend(Webrat::Matchers)
  session.extend(Webrat::HaveTagMatcher)
  session
end
