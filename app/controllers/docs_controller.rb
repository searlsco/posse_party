class DocsController < ApplicationController
  BASE_URL = "https://github.com/searlsco/posse_party/blob/main/docs/"
  DOC_PATHS = {
    "mastodon-account-setup" => "account_setup/mastodon",
    "bsky-account-setup" => "account_setup/bsky",
    "x-account-setup" => "account_setup/x"
  }.freeze

  skip_before_action :redirect_to_registration_if_no_users

  def index
    redirect_to BASE_URL, allow_other_host: true
  end

  def show
    path = DOC_PATHS.fetch(params[:id], params[:id])
    redirect_to "#{BASE_URL}#{path}.md", allow_other_host: true
  end
end
