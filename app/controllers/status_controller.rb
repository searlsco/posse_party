class StatusController < Rails::HealthController
  def show
    @status_verification = ChecksSystemStatus.new.check(cache: false)

    render :show, layout: false
  end
end
