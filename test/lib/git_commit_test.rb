require "test_helper"

class GitCommitTest < ActiveSupport::TestCase
  def test_returns_env_sha_and_link
    commit = GitCommit.new.identify(
      env: {"GIT_COMMIT" => "a1b2c3d4e5f6"},
      repo_path: Pathname.new(File::NULL)
    )

    assert_equal "a1b2c3d4e5f6", commit.sha
    assert_equal "a1b2c3d", commit.short_sha
    assert_equal "https://github.com/searlsco/posse_party/commit/a1b2c3d4e5f6", commit.url
  end

  def test_falls_back_to_local_repo
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        system("git init -q")
        File.write("README.md", "hi")
        system("git add README.md")
        system("git -c user.email=test@example.com -c user.name=test commit -q -m 'test'")
        sha = `git rev-parse HEAD`.strip

        commit = GitCommit.new.identify(env: {}, repo_path: Pathname.new(dir))

        assert_equal sha, commit.sha
        assert_equal sha.first(7), commit.short_sha
      end
    end
  end

  def test_returns_nil_when_unavailable
    assert_nil GitCommit.new.identify(env: {}, repo_path: Pathname.new("/missing"))
  end
end
