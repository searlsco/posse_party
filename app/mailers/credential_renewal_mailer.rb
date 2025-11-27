class CredentialRenewalMailer < ApplicationMailer
  def renew_linkedin
    send_renewal(
      account: params[:account],
      subject: "Renew your LinkedIn connection for POSSE Party"
    )
  end

  def renew_youtube
    send_renewal(
      account: params[:account],
      subject: "Renew your YouTube connection for POSSE Party"
    )
  end

  private

  def send_renewal(account:, subject:)
    @account = account
    result = GeneratesPlatformRenewalUrl.new.generate(@account)
    raise result.error if result.failure?
    @oauth_url = result.data

    mail(to: @account.user.email, subject:)
  end
end
