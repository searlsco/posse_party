class AccountsController < MembersController
  set_tab :accounts

  def index
    @accounts = current_user.accounts.order("active desc, platform_tag asc, created_at asc")
  end

  def set_syndication
    raw_value = Array(params[:enabled]).last
    enabled = ActiveModel::Type::Boolean.new.cast(raw_value)
    current_user.update!(allow_automatic_syndication: enabled)
    notice = "Automatic syndication was successfully #{enabled ? "enabled" : "disabled"}."
    respond_to do |format|
      format.html { redirect_to accounts_path, notice: notice }
      format.turbo_stream do
        flash.now[:notice] = notice
      end
    end
  end

  def new
    @account = current_user.accounts.build(platform_tag: "bsky")
  end

  def edit
    @account = current_user.accounts.includes(:crossposts).find(params[:id])
  end

  def create
    result = PersistsAccount.new.create(user: current_user, params: params)

    if result.success?
      flash[:alert] = result.backfill_message unless result.backfill_success?
      redirect_to accounts_path, notice: "Account created successfully"
    else
      @account = result.account
      flash[:alert] = result.error_messages.join(", ")
      render :new, status: :unprocessable_content
    end
  end

  def credential_fields
    @account = if params[:id].present?
      current_user.accounts.find(params[:id])
    else
      current_user.accounts.build(platform_tag: params[:platform_tag])
    end

    content = render_to_string(partial: "credential_fields", locals: {account: @account})

    render html: "<turbo-frame id=\"credential_fields\" class=\"md:col-span-2\">#{content}</turbo-frame>".html_safe, layout: false
  end

  def override_fields
    @account = if params[:id].present?
      current_user.accounts.find(params[:id])
    else
      current_user.accounts.build(platform_tag: params[:platform_tag])
    end

    content = if @account.platform_tag.present?
      view_context.fields_for(:account, @account) do |f|
        render_to_string(partial: "override_fields", locals: {account: @account, f: f})
      end
    else
      ""
    end

    render html: "<turbo-frame id=\"override_fields\" class=\"md:col-span-2\">#{content}</turbo-frame>".html_safe, layout: false
  end

  def update
    result = PersistsAccount.new.update(user: current_user, params: params)

    if result.success?
      notify_user_of_account_update!(result.account)
      redirect_to edit_account_path(result.account), notice: "Account updated successfully"
    else
      @account = result.account
      flash[:alert] = result.error_messages.join(", ")
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @account = current_user.accounts.includes(:crossposts).find(params[:id])
    crosspost_count = @account.crossposts.count

    @account.destroy!

    flash[:notice] = if crosspost_count > 0
      "Account deleted successfully. #{crosspost_count} associated crosspost(s) were also deleted."
    else
      "Account deleted successfully."
    end

    redirect_to accounts_path
  end

  def renew_credentials
    @account = current_user.accounts.find(params[:id])
    result = GeneratesPlatformRenewalUrl.new.generate(@account)

    if result.success?
      redirect_to result.data, allow_other_host: true
    else
      flash[:alert] = result.error
      redirect_to accounts_path
    end
  end

  private

  def notify_user_of_account_update!(account)
    filtered_credentials = FiltersParametersFromJson.filter(account.credentials.to_json)

    NotifiesUser.new.notify(
      user: current_user,
      title: "#{account.notification_label} updated",
      severity: "info",
      text: filtered_credentials.presence || "No stored credentials",
      refs: [{"model" => "Account", "id" => account.id}]
    )
  end
end
