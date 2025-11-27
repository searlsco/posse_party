VCR.configure do |config|
  config.cassette_library_dir = "test/support/vcr_cassettes"
  config.allow_http_connections_when_no_cassette = true
  config.hook_into :webmock
end

module VcrHelpers
  def perfect_vcr_match(cassette, record: false, time: nil, except: [], &blk)
    FileUtils.rm_f("test/support/vcr_cassettes/#{cassette}.yml") if record
    VCR.use_cassette(cassette, record: (record ? :all : :none), match_requests_on: [:method, :uri, :body, :headers] - except, allow_playback_repeats: false) do
      puts_sql_changes(enabled: record) do
        if time.present?
          fake_time!(time, freeze: true, &blk)
        else
          blk.call
        end
      end
    end
  end

  def vcr_secrets(hash)
    VCR.configure do |config|
      hash.each do |k, v|
        # When real secrets are absent, use deterministic per-key placeholders
        # so that each secret position is distinguishable and validated.
        placeholder = v || "SOME_#{k.to_s.upcase}"
        config.filter_sensitive_data("{{#{k}}}") { placeholder }
      end
    end

    return hash unless hash.values.any?(&:nil?)
    hash.map { |k, v| [k, v || "SOME_#{k.to_s.upcase}"] }.to_h
  end

  def puts_sql_changes(io: $stdout, enabled: true, &blk)
    return blk.call unless enabled

    writes = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |*_args, payload|
      next if payload[:name] == "SCHEMA"
      if /\A\s*(INSERT|UPDATE|DELETE)\b/i.match?(sql = payload[:sql])
        writes << [sql, payload[:type_casted_binds] || payload[:binds]]
      end
    end

    blk.call
  ensure
    if enabled
      ActiveSupport::Notifications.unsubscribe(sub) if sub
      io.puts "== SQL INSERT, UPDATE, DELETE statements =="
      writes.each do |sql, binds|
        if binds&.any?
          bind_str = binds.map { |b| b.respond_to?(:name) ? "#{b.name}=#{b.value_before_type_cast.inspect}" : b.inspect }.join(", ")
          io.puts "#{sql}  /* binds: #{bind_str} */"
        else
          io.puts sql
        end
      end
    end
  end
end
