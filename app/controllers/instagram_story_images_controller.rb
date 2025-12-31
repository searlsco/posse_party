class InstagramStoryImagesController < ApplicationController
  skip_before_action :redirect_to_registration_if_no_users

  def show
    temporary_asset = TemporaryAsset.find_by(key: params[:key])
    return head(:not_found) if temporary_asset.blank? || temporary_asset.bytes.blank?

    send_data temporary_asset.bytes, type: temporary_asset.content_type, disposition: "inline"
  end
end
