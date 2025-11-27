require "test_helper"

class ConfiguresMailerTest < ActiveSupport::TestCase
  setup do
    @aws_config_before = Aws.config.dup
    @env_backup = ENV.to_hash
    @delivery_methods_before = ActionMailer::Base.delivery_methods.keys
    @smtp_settings_before = ActionMailer::Base.smtp_settings
  end

  teardown do
    Aws.config.clear
    Aws.config.update(@aws_config_before)
    ENV.replace(@env_backup)
    ActionMailer::Base.smtp_settings = @smtp_settings_before
  end

  test "defaults to amazon ses when MAIL_PROVIDER is blank and aws credentials exist" do
    ENV.delete("MAIL_PROVIDER")
    ENV["AWS_SES_REGION"] = "us-east-1"
    ENV["AWS_SES_ACCESS_KEY_ID"] = "key"
    ENV["AWS_SES_SECRET_ACCESS_KEY"] = "secret"

    delivery_method = ConfiguresMailer.new.configure!

    assert_equal :ses_api, delivery_method
    assert_equal "us-east-1", Aws.config[:region]
    assert_equal "key", Aws.config[:access_key_id]
    assert_equal "secret", Aws.config[:secret_access_key]
  end

  test "falls back to resend when MAIL_PROVIDER is blank and resend api key exists" do
    ENV.delete("MAIL_PROVIDER")
    ENV["RESEND_API_KEY"] = "rk"

    delivery_method = ConfiguresMailer.new.configure!

    assert_equal :resend_api, delivery_method
  end

  test "picks sendgrid when MAIL_PROVIDER is blank and sendgrid key exists" do
    ENV.delete("MAIL_PROVIDER")
    ENV["SENDGRID_API_KEY"] = "sg"

    delivery_method = ConfiguresMailer.new.configure!

    assert_equal :sendgrid_api, delivery_method
  end

  test "chooses provider explicitly set by MAIL_PROVIDER" do
    ENV["MAIL_PROVIDER"] = "postmark"
    ENV["POSTMARK_API_TOKEN"] = "token"

    delivery_method = ConfiguresMailer.new.configure!

    assert_equal :postmark_api, delivery_method
  end

  test "raises when MAIL_PROVIDER is unknown" do
    ENV["MAIL_PROVIDER"] = "mystery"

    error = assert_raises(ArgumentError) { ConfiguresMailer.new.configure! }

    assert_includes error.message, "Unknown MAIL_PROVIDER"
  end
end
