class TestController < ActionController::Base # standard:disable Rails/ApplicationController
  if Rails.env.local?
    def set_session_var
      session[params[:key]] = params[:value] # brakeman:disable
      redirect_back fallback_location: settings_path
    end

    def feed_fixture
      fixture_name = File.basename(params[:fixture].to_s)
      return head(:not_found) if fixture_name.blank?

      fixture_path = Rails.root.join("test/fixtures/files", fixture_name)

      if File.file?(fixture_path)
        send_data File.binread(fixture_path), type: "application/atom+xml", disposition: "inline"
      else
        head :not_found
      end
    end

    def latest_email
      letter_opener_path = Rails.root.join("tmp/letter_opener")

      if Dir.exist?(letter_opener_path)
        # Get the most recent directory (lexicographically last)
        email_dirs = Dir.entries(letter_opener_path)
          .reject { |d| d.start_with?(".") }
          .map { |d| File.join(letter_opener_path, d) }
          .select { |path| File.directory?(path) }
          .max

        if email_dirs
          # Look for HTML files in the directory
          html_file = Dir.glob(File.join(email_dirs, "*.html")).first

          if html_file
            html_content = File.read(html_file)
            render html: html_content.html_safe
          else
            render plain: "❌ No HTML file found in latest email directory", status: :not_found
          end
        else
          render plain: "❌ No email directories found", status: :not_found
        end
      else
        render plain: "❌ Letter opener directory not found", status: :not_found
      end
    end
  end
end
