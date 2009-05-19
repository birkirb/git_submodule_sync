TEMP_DIRECTORY = '/tmp/spec_testing'

def set_file_paths
  @test_dir = File.join(File.dirname(__FILE__), 'files')
  @git_sub_bare = File.join(@test_dir, 'git', 'submodule.git')
  @git_usesub_bare = File.join(@test_dir, 'git', 'using_submodule.git')
end

def create_temp_repo(clone_path)
  tmp_path = File.join(TEMP_DIRECTORY, clone_path.split('/').last.split('.')[0])
  FileUtils.mkdir_p(tmp_path)
  FileUtils.cp_r(clone_path, File.join(tmp_path, '.git'))
  tmp_path
end

def remove_temp_directory
  FileUtils.rm_r(TEMP_DIRECTORY)
end
