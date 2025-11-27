class Platforms::Youtube
  class PotentiallyTellsUserToRenewYoutubeAccessToken
    def potentially_tell(account)
      if should_send_renewal_reminder?(account)
        NotifiesUser.new.notify(
          mail: CredentialRenewalMailer,
          method: :renew_youtube,
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
      renewal_reminder_sent_at = account.credentials["renewal_reminder_sent_at"]
      refresh_token_expires_at = account.credentials["refresh_token_expires_at"]

      !within_cooldown_period?(renewal_reminder_sent_at) && refresh_token_expires_soon?(refresh_token_expires_at)
    end

    def refresh_token_expires_soon?(refresh_token_expires_at)
      return true if refresh_token_expires_at.nil?  # No expiry info, better to remind

      begin
        Time.zone.parse(refresh_token_expires_at) <= Now.from_now(Constants::YOUTUBE_RENEWAL_WINDOW_DAYS.days)
      rescue ArgumentError
        true  # Invalid date format, better to remind
      end
    end

    def within_cooldown_period?(renewal_reminder_sent_at)
      return false if renewal_reminder_sent_at.nil?

      begin
        Time.zone.parse(renewal_reminder_sent_at) > Now.ago(Constants::YOUTUBE_REMINDER_COOLDOWN_HOURS.hours)
      rescue ArgumentError
        false  # Invalid date format, no cooldown
      end
    end
  end
end
