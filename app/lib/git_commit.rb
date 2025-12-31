require "open3"

class GitCommit
  Commit = Struct.new(:sha, :short_sha, :url, keyword_init: true)

  def identify(env: ENV, repo_path: Rails.root)
    sha = normalize(env["GIT_COMMIT"])
    sha ||= normalize(rev_parse_head(repo_path))
    return unless sha

    Commit.new(
      sha: sha,
      short_sha: sha.first(7),
      url: "https://github.com/searlsco/posse_party/commit/#{sha}"
    )
  end

  private

  def rev_parse_head(repo_path)
    return unless repo_path.join(".git").exist?

    stdout, status = Open3.capture2("git", "-C", repo_path.to_s, "rev-parse", "HEAD")
    stdout.strip if status.success?
  rescue
    nil
  end

  def normalize(raw_sha)
    sha = raw_sha.to_s.strip.downcase
    sha if sha.match?(/\A[0-9a-f]{7,40}\z/)
  end
end
