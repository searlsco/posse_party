class CredentialRenewalMailerPreview < ActionMailer::Preview
  def renew_linkedin
    account = Account.find_by(platform_tag: "linkedin", active: true)
    CredentialRenewalMailer.with(account: account).renew_linkedin
  end

  def renew_youtube
    account = Account.find_by(platform_tag: "youtube", active: true)
    CredentialRenewalMailer.with(account: account).renew_youtube
  end
end
