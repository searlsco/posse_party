class CredentialRenewalsController < ApplicationController
  def linkedin
    result = Platforms::Linkedin::RenewsLinkedInTokenFromOAuthCallback.new.renew(
      code: params[:code],
      state: params[:state]
    )
    notification_user = result.account&.user || current_user

    if result.success?
      flash[:notice] = "LinkedIn credentials successfully renewed!"
      if notification_user
        NotifiesUser.new.notify(
          user: notification_user,
          title: "#{result.account.notification_label} credentials renewed",
          severity: "info",
          text: "Credentials for account #{result.account.label} (linkedin) were renewed.",
          refs: [{"model" => "Account", "id" => result.account.id}]
        )
      end
      redirect_to edit_account_path(result.account)
    else
      flash[:alert] = "LinkedIn credential renewal failed. Please try again."
      if notification_user
        NotifiesUser.new.notify(
          user: notification_user,
          title: (result.account ? "#{result.account.notification_label} authorization failed" : "LinkedIn authorization failed"),
          severity: "danger",
          text: result.message || "LinkedIn authorization failed",
          refs: (result.account ? [{"model" => "Account", "id" => result.account.id}] : [])
        )
      end
      redirect_to result.account ? edit_account_path(result.account) : accounts_path
    end
  end

  def youtube
    result = Platforms::Youtube::ExchangesYoutubeToken.new.exchange(
      params[:code],
      params[:state]
    )
    notification_user = result.account&.user || current_user

    if result.success?
      flash[:notice] = "YouTube credentials successfully renewed!"
      if notification_user
        NotifiesUser.new.notify(
          user: notification_user,
          title: "#{result.account.notification_label} credentials renewed",
          severity: "info",
          text: "Credentials for account #{result.account.label} (youtube) were renewed.",
          refs: [{"model" => "Account", "id" => result.account.id}]
        )
      end
      redirect_to edit_account_path(result.account)
    else
      flash[:alert] = "YouTube credential renewal failed. Please try again."
      if notification_user
        NotifiesUser.new.notify(
          user: notification_user,
          title: (result.account ? "#{result.account.notification_label} authorization failed" : "YouTube authorization failed"),
          severity: "danger",
          text: result.message || "YouTube authorization failed",
          refs: (result.account ? [{"model" => "Account", "id" => result.account.id}] : [])
        )
      end
      redirect_to result.account ? edit_account_path(result.account) : accounts_path
    end
  end
end
