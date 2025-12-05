module EnvChecks
  class LibidnCheck
    def check(require_fn: Kernel.method(:require))
      require_fn.call("idn")
      true
    rescue LoadError
      raise <<~MSG
        Missing libidn system library required by idn-ruby (pulled in by twitter-text).

        Install the system package and re-bundle:
          - macOS:   brew install libidn
          - Debian/Ubuntu: sudo apt-get install -y libidn12 libidn-dev
          - Alpine:  apk add --no-cache libidn libidn-dev

        After installing, run: bundle install
      MSG
    end
  end
end
