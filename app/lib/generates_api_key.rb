class GeneratesApiKey
  def generate
    SecureRandom.hex(32)
  end
end
