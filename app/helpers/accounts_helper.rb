module AccountsHelper
  CREDENTIAL_LABEL_EXCEPTIONS = {
    "api" => "API",
    "id" => "ID",
    "url" => "URL"
  }.freeze

  def to_credentials_label(credential_key)
    credential_key
      .to_s
      .humanize(keep_id_suffix: true)
      .titleize
      .split(/\s+/)
      .map { |word| CREDENTIAL_LABEL_EXCEPTIONS.fetch(word.downcase, word) }
      .join(" ")
  end
end
