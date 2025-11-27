class Platforms::Linkedin
  class PotentiallyTellsUserToRenewLinkedinAccessToken
    def potentially_tell(account)
      if should_send_renewal_reminder?(account)
        NotifiesUser.new.notify(
          mail: CredentialRenewalMailer,
          method: :renew_linkedin,
          params: {account: account},
          user: account.user,
          title: "#{account.notification_label} renewal required",
          severity: "warn",
          refs: [{"model" => "Account", "id" => account.id}],
          badge: true
        )
        account.update!(
          credentials: account.credentials.merge("renewal_reminder_sent_at" => Now.time.iso8601)
        )
      end
    end

    private

    def should_send_renewal_reminder?(account)
      expires_at = account.credentials["expires_at"]
      renewal_reminder_sent_at = account.credentials["renewal_reminder_sent_at"]

      !within_cooldown_period?(renewal_reminder_sent_at) && (expires_at.nil? || expires_at_soon?(expires_at))
    end

    def expires_at_soon?(expires_at)
      return true unless expires_at.is_a?(String) && (parsed_time = Time.zone.parse(expires_at))

      parsed_time <= Now.from_now(Constants::LINKEDIN_RENEWAL_WINDOW_DAYS.days)
    rescue ArgumentError
      true
    end

    def within_cooldown_period?(renewal_reminder_sent_at)
      return false if renewal_reminder_sent_at.nil?

      Time.zone.parse(renewal_reminder_sent_at) > Now.time - Constants::LINKEDIN_REMINDER_COOLDOWN_HOURS.hours
    end
  end
end
