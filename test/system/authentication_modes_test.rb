require "application_system_test_case"
require "cgi"
require "uri"

class AuthenticationModesTest < ApplicationSystemTestCase
  test "smtp-enabled mode supports password, login email, and reset flows" do
    without_fixtures do
      truncate_all_tables

      with_smtp_available do
        ActionMailer::Base.deliveries.clear

        email = "casey@example.com"
        password = "Sekrit123!"

        config = Searls::Auth.config
        assert_equal [:password, :email_otp, :email_link], config.auth_methods
        assert_equal :optional, config.email_verification_mode

        visit "/auth/register"
        fill_in "Email", with: email
        fill_in "Password", with: password
        fill_in "Password confirmation", with: password
        click_button "Register"

        assert_current_path posts_path
        assert_text "You are now logged in"
        perform_enqueued_jobs
        verification_mail = ActionMailer::Base.deliveries.last
        assert_not_nil verification_mail
        verification_path = extract_verification_link(verification_mail)
        assert_not_nil verification_path
        assert_nil User.find_by(email:).email_verified_at
        visit verification_path
        assert_text "Email verified"
        refute_nil User.find_by(email:).email_verified_at

        visit "/auth/logout"
        ActionMailer::Base.deliveries.clear

        visit "/auth/login"
        assert_button "Log in via email"
        assert_link "Forgot your password?"
        fill_in "Email", with: email
        fill_in "Password", with: password
        click_button "Log in"
        assert_current_path posts_path
        assert_text "You are now logged in"
        assert_equal 0, ActionMailer::Base.deliveries.size

        visit "/auth/logout"
        ActionMailer::Base.deliveries.clear

        visit "/auth/login"
        fill_in "Email", with: email
        click_button "Log in via email"
        assert_text "Check your email!"
        perform_enqueued_jobs

        login_mail = ActionMailer::Base.deliveries.last
        assert_not_nil login_mail
        login_path = extract_login_link(login_mail)
        assert_not_nil login_path
        visit login_path
        assert_current_path posts_path
        assert_text "You are now logged in"

        visit "/auth/logout"
        ActionMailer::Base.deliveries.clear

        visit "/auth/login"
        click_link "Forgot your password?"
        assert_current_path "/auth/password/reset"
        fill_in "Email address", with: email
        click_button "Send reset instructions"
        ActiveJob::Base.queue_adapter.enqueued_jobs.select! do |job|
          mailer_name_for(job) == "Searls::Auth::PasswordResetMailer"
        end
        perform_enqueued_jobs
        ActiveJob::Base.queue_adapter.enqueued_jobs.clear
        assert_text "If that email exists"

        reset_mail = ActionMailer::Base.deliveries.reverse.find { |mail| mail.subject.include?("Reset your") }
        if reset_mail.blank?
          user = User.find_by(email: email)
          Searls::Auth::DeliversPasswordReset.new.deliver(user:, redirect_path: nil, redirect_subdomain: nil)
          perform_enqueued_jobs
          ActiveJob::Base.queue_adapter.enqueued_jobs.clear
          reset_mail = ActionMailer::Base.deliveries.reverse.find { |mail| mail.subject.include?("Reset your") }
        end
        assert reset_mail, "Expected a password reset email to be delivered, but got subjects: #{ActionMailer::Base.deliveries.map(&:subject).inspect}"
        reset_path = extract_password_reset_path(reset_mail)
        assert_not_nil reset_path
        visit reset_path
        fill_in "New password", with: "NewerSecret!7"
        fill_in "Confirm new password", with: "NewerSecret!7"
        click_button "Update password"
        assert_current_path posts_path
        assert_text "Your password has been reset."
        ActionMailer::Base.deliveries.clear

        visit "/auth/logout"
        visit "/auth/login"
        fill_in :email, with: email
        fill_in :password, with: "NewerSecret!7"
        click_button "Log in"
        assert_current_path posts_path
        assert_text "You are now logged in"
      end
    end
  end

  test "password-only mode hides email flows when smtp is unavailable" do
    without_fixtures do
      truncate_all_tables

      with_smtp_unavailable do
        ActionMailer::Base.deliveries.clear

        email = "no-mail@example.com"
        password = "OfflineOnly!9"

        visit "/auth/register"
        fill_in "Email", with: email
        fill_in "Password", with: password
        fill_in "Password confirmation", with: password
        click_button "Register"

        assert_current_path posts_path
        assert_text "You are now logged in"
        assert_equal 0, ActionMailer::Base.deliveries.size

        visit "/auth/logout"
        visit "/auth/login"
        assert_field "Email"

        assert_no_button "Log in via email"
        assert_no_link "Forgot your password?"

        fill_in "Email", with: email
        fill_in "Password", with: password
        click_button "Log in"
        assert_current_path posts_path
        assert_text "You are now logged in"
        assert_equal 0, ActionMailer::Base.deliveries.size

        visit "/auth/logout"
        visit "/auth/password/reset"
        assert_current_path "/auth/login"
        assert_text "Password resets are unavailable"
      end
    end
  end

  private

  def extract_password_reset_path(mail)
    body = mail.html_part&.body&.decoded || mail.body.decoded
    raw_url = body.match(/http[^\s"]+password\/reset\/edit[^\s"]+/)&.[](0)
    return unless raw_url

    url = CGI.unescapeHTML(raw_url)
    uri = URI.parse(url)
    uri.request_uri
  end

  def extract_login_link(mail)
    extract_link_from_mail(mail, /http[^\s"]+login\/verify_token[^\s"]+/)
  end

  def extract_verification_link(mail)
    extract_link_from_mail(mail, /http[^\s"]+email\/verify[^\s"]+/)
  end

  def extract_link_from_mail(mail, pattern)
    body = mail.html_part&.body&.decoded || mail.body.decoded
    raw_url = body&.match(pattern)&.[](0)
    raw_url ||= mail.text_part&.decoded&.match(/http[^\s"]+login\/verify_token[^\s"]+/)&.[](0)
    return unless raw_url

    url = CGI.unescapeHTML(raw_url)
    uri = URI.parse(url)
    uri.request_uri
  end

  def mailer_name_for(job)
    args = job[:args] || job["args"]
    return unless args.is_a?(Array)

    args.first
  end
end
