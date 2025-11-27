class CrosspostsController < MembersController
  set_tab :posts

  def show
    @crosspost = current_user.crossposts.includes(:feed, :post, :account).find(params[:id])
    @content_preview = compose_content_preview(@crosspost)
    default_crosspost_options = PublishesCrosspost::MatchesPlatformApi.new.match(@crosspost.account).default_crosspost_options
    @config = PublishesCrosspost::MungesConfig.new.munge(@crosspost, default_crosspost_options)
    @provenance = DeterminesProvenanceOfCrosspostConfig.new.determine(@crosspost, default_crosspost_options)
  end

  def publish
    @crosspost = current_user.crossposts.find(params[:id])
    manually_publishes_crosspost = ManuallyPublishesCrosspost.new

    if (outcome = manually_publishes_crosspost.publish(@crosspost)).success?
      redirect_to crosspost_path(@crosspost), notice: "Crosspost (re)publish requested"
    else
      redirect_to crosspost_path(@crosspost), alert: outcome.error
    end
  end

  def skip
    @crosspost = current_user.crossposts.find(params[:id])
    manually_skips_crosspost = ManuallySkipsCrosspost.new

    if (outcome = manually_skips_crosspost.skip(@crosspost)).success?
      redirect_to crosspost_path(@crosspost), notice: "Crosspost skipped"
    else
      redirect_to crosspost_path(@crosspost), alert: outcome.message
    end
  end

  def destroy
    @crosspost = current_user.crossposts.find(params[:id])
    outcome = DeletesCrosspost.new.delete(@crosspost)

    if outcome.success?
      redirect_to post_path(@crosspost.post_id), notice: outcome.message
    else
      redirect_to crosspost_path(@crosspost), alert: outcome.message
    end
  end

  private

  def compose_content_preview(crosspost)
    matches_platform_api = PublishesCrosspost::MatchesPlatformApi.new
    munges_config = PublishesCrosspost::MungesConfig.new
    composes_crosspost_content = PublishesCrosspost::ComposesCrosspostContent.new

    api = matches_platform_api.match(crosspost.account)
    crosspost_config = munges_config.munge(crosspost, api.default_crosspost_options)

    if crosspost_config.syndicate
      composes_crosspost_content.compose(crosspost_config, api.post_constraints).string
    else
      "[Would be skipped - syndication disabled]"
    end
  rescue => e
    "[Error generating preview: #{e.message}]\n\n#{e.backtrace.join("\n")}"
  end
end
