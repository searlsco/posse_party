if Gem.loaded_specs["twitter-text"]
  require Rails.root.join("app/lib/env_checks/libidn_check").to_s
  EnvChecks::LibidnCheck.new.check
end
