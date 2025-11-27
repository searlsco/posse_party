module Middleware
  class ConditionalGetFileHandler
    FILE_TYPES = %w[text/html application/xml application/json application/xsd].freeze

    RFC2616_DATE_REGEX = /\A(?:
      # RFC 1123: "Sun, 06 Nov 1994 08:49:37 GMT"
      (?:(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s\d{2}\s(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s\d{4}\s\d{2}:\d{2}:\d{2}\sGMT) |
      # RFC 850: "Sunday, 06-Nov-94 08:49:37 GMT"
      (?:(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),\s\d{2}-(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\d{2}\s\d{2}:\d{2}:\d{2}\sGMT) |
      # asctime: "Sun Nov  6 08:49:37 1994"
      (?:(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s(?:\d{2}| \d)\s\d{2}:\d{2}:\d{2}\s\d{4})
    )/x

    def initialize(app, path, index: "index", headers: {})
      @app = app
      @root = path
      @file_handler = ActionDispatch::FileHandler.new(path, index: index, headers: headers)
      @etag_cache = {}
    end

    def call(env)
      request = Rack::Request.new(env)

      if (status, headers, body = @file_handler.attempt(env))
        if status == 200 && FILE_TYPES.include?(headers["content-type"])
          filepath, _ = @file_handler.send(:find_file, request.path_info, accept_encoding: request.accept_encoding)
          write_etag_and_last_modified_headers!(filepath, headers)
        end

        if etag_match?(request, headers) || not_modified_since?(request, headers)
          [304, headers, []]
        else
          [status, headers, body]
        end
      else
        @app.call(env)
      end
    end

    private

    def write_etag_and_last_modified_headers!(filepath, headers)
      full_path = File.join(@root, Rack::Utils.clean_path_info(filepath))

      if File.exist?(full_path)
        etag, last_modified = cached_etag(full_path)

        headers["ETag"] = "\"#{etag}\""
        headers["Last-Modified"] = last_modified
      end
    end

    def etag_match?(request, headers)
      return false if request.env["HTTP_IF_NONE_MATCH"].blank? || headers["ETag"].blank?

      request.env["HTTP_IF_NONE_MATCH"] == headers["ETag"]
    end

    def not_modified_since?(request, headers)
      return false if request.env["HTTP_IF_MODIFIED_SINCE"].blank? || headers["Last-Modified"].blank?

      # Some user agents / router combos (*cough* Safari+Heroku) will merge headers and result in multiple comma-separated dates
      if (first_requested_date = request.env["HTTP_IF_MODIFIED_SINCE"][RFC2616_DATE_REGEX])
        Time.httpdate(first_requested_date) >= Time.httpdate(headers["Last-Modified"])
      end
    end

    def cached_etag(file_path)
      @etag_cache[file_path] ||= begin
        etag = Digest::MD5.file(file_path).hexdigest
        last_modified = File.mtime(file_path).httpdate
        [etag, last_modified]
      rescue => e
        Rails.logger.warn "Failed to generate ETag for #{file_path}: #{e.message}"
        [nil, nil]
      end
    end
  end
end
