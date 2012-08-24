Before do
  require 'spec_helper'
  ::LOCAL_REPOS = File.join(Dir.pwd, 'spec', 'files', 'test_repos')
  initalize_repos
  @commitish = change_submodule_via_third_party_checkout.sha
end

After do
  FileUtils.rm_r(LOCAL_REPOS) if File.exists?(LOCAL_REPOS)
end
