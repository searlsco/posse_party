class CrosspostsController < MembersController
  set_tab :posts

  def show
    @crosspost = current_user.crossposts.includes(:feed, :post, :account).find(params[:id])
    @preview = ComposesCrosspostPreview.new.compose(@crosspost)
    @preview_media = ComposesCrosspostPreview.new.media(@crosspost)
    default_crosspost_options = PublishesCrosspost::MatchesPlatformApi.new.match(@crosspost.account).default_crosspost_options
    @config = PublishesCrosspost::MungesConfig.new.munge(@crosspost, default_crosspost_options)
    @provenance = DeterminesProvenanceOfCrosspostConfig.new.determine(@crosspost, default_crosspost_options)
  end

  # Serves the crosspost's images as PNGs so they can be copied into a platform's own composer
  def media
    crosspost = current_user.crossposts.includes(:account, :post).find(params[:id])

    if (image = PreparesComposeMedia.new.prepare(crosspost, params[:index].to_i)).nil?
      head :not_found
    else
      send_data image.bytes, type: "image/png", filename: image.filename, disposition: "inline"
    end
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

  def mark_published
    @crosspost = current_user.crossposts.find(params[:id])
    outcome = MarksCrosspostPublished.new.mark(@crosspost, params[:url])

    redirect_to crosspost_path(@crosspost), outcome.flash_type => outcome.message
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
end
