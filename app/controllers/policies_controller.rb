class PoliciesController < ApplicationController
  skip_before_action :redirect_to_registration_if_no_users
  layout "modal"
  before_action :set_policy_context

  def privacy
  end

  private

  def set_policy_context
    @policy_context = Policies::BuildsPolicyContext.new.build(request)
  end
end
