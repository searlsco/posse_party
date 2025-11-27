class RegeneratesApiKey
  def initialize
    @generates_api_key = GeneratesApiKey.new
  end

  def regenerate(user)
    user.api_key = @generates_api_key.generate

    if user.save
      Outcome.success("API key regenerated successfully")
    else
      Outcome.failure("Failed to regenerate API key")
    end
  end
end
