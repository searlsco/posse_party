module Middleware
  class NotifiesAdminsOnException
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue => e
      begin
        status = status_code_for(e)
        if status >= 500
          request = ActionDispatch::Request.new(env)
          body = <<~MSG
            { method: #{request.request_method}, path: #{request.fullpath}, request_id: #{request.request_id} }

            #{e.class}: #{e.message}
            #{Array(e.backtrace).join("\n")}
          MSG
          NotifiesAdmins.new.call(subject: "POSSE Party #{status} Error: #{e.message.to_s.truncate(60)}", body: body, severity: "danger")
        end
      ensure
        raise e
      end
    end

    private

    def status_code_for(exception)
      ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
    rescue
      500
    end
  end
end
