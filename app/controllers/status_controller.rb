class StatusController < Rails::HealthController
  def show
    @status_verification = ChecksSystemStatus.new.check(cache: false)
    @git_commit = GitCommit.new.identify

    render :show, layout: false
  end
end
