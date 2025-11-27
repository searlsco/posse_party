class PersistsAccount
  Result = Struct.new(:success?, :account, :error_messages, :error, :backfill_success?, :backfill_message, keyword_init: true)

  PERMITTED_PARAMS = [
    :label, :platform_tag, :active, :manually_create_crossposts, :credentials, :manually_publish_crossposts, :crosspost_cooldown, :crosspost_min_age,
    :format_string, :truncate, :append_url, :append_url_if_truncated, :append_url_spacer, :append_url_label, :attach_link, :og_image,
    {disabled_feed_ids: []}
  ].freeze

  def initialize
    @backfills_missing_crossposts = CreatesMissingCrosspostsForAccount.new
  end

  def create(user:, params:)
    account_params = params.require(:account)
    attrs = normalize_for_create(user, account_params)
    account = user.accounts.build

    result = save_account(account, attrs, params: params)
    return result unless result.success?

    outcome = @backfills_missing_crossposts.create(account: account)
    Result.new(
      success?: true,
      account: account,
      error_messages: [],
      error: nil,
      backfill_success?: outcome.success?,
      backfill_message: outcome.message
    )
  end

  def update(user:, params:)
    account = user.accounts.includes(:crossposts).find(params[:id])
    account_params = params.require(:account)
    attrs = normalize_for_update(user, account_params)
    save_account(account, attrs, params: params)
  end

  private

  def normalize_for_create(user, account_params)
    permitted = account_params.permit(*PERMITTED_PARAMS).to_h
    if permitted.key?(:disabled_feed_ids)
      permitted[:disabled_feed_ids] = filter_disabled_feed_ids(user, permitted[:disabled_feed_ids])
    end
    permitted
  end

  def normalize_for_update(user, account_params)
    permitted = account_params.permit(*PERMITTED_PARAMS).to_h
    permitted[:disabled_feed_ids] = [] unless permitted.key?(:disabled_feed_ids)
    if permitted.key?(:disabled_feed_ids)
      permitted[:disabled_feed_ids] = filter_disabled_feed_ids(user, permitted[:disabled_feed_ids])
    end
    permitted
  end

  def save_account(account, attrs, params:)
    begin
      account.assign_attributes(attrs)
      if params[:account_credentials].present?
        merge_required_credentials!(account, params[:account_credentials])
      end
      ok = account.save
    rescue JSON::ParserError => e
      account.errors.add(:credentials, "Invalid JSON: #{e.message}")
      if account.persisted?
        account.reload
      else
        account.credentials = {}
      end
      ok = false
    end

    errors = account.errors.full_messages
    Result.new(success?: ok, account: account, error_messages: errors, error: errors.first, backfill_success?: true, backfill_message: nil)
  end

  def filter_disabled_feed_ids(user, ids)
    own_ids = Array(user&.feeds&.pluck(:id))
    Array(ids).map(&:to_i) & own_ids
  end

  def merge_required_credentials!(account, credential_params)
    required = account.required_credentials
    allowed = credential_params.respond_to?(:permit) ? credential_params.permit(*required) : credential_params.slice(*required)
    account.credentials = (account.credentials || {}).merge(allowed.to_h)
  end
end
