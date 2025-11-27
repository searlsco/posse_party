class DocsController < ApplicationController
  BASE_URL = "https://github.com/searlsco/posse_party/blob/main/docs/"

  skip_before_action :redirect_to_registration_if_no_users

  def index
    redirect_to BASE_URL, allow_other_host: true
  end

  def show
    redirect_to "#{BASE_URL}#{params[:id]}.md", allow_other_host: true
  end
end
