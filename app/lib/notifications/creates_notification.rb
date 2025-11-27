class Notifications::CreatesNotification
  def create!(user:, title:, severity:, text:, refs: [], badge: false)
    sev = coerce_severity(severity)
    normalized_refs = normalize_refs(refs)
    Notification.create!(user:, title:, severity: sev, text:, refs: normalized_refs, badge:)
  end

  private

  def coerce_severity(severity)
    str = severity.to_s
    if Notification::SEVERITIES.include?(str)
      str
    else
      "info"
    end
  end

  def normalize_refs(refs)
    Array(refs).filter_map do |ref|
      next unless ref.is_a?(Hash)
      if ref["url"].present?
        {"url" => ref["url"].to_s}
      elsif ref["model"].present? && ref["id"].present?
        {"model" => ref["model"].to_s, "id" => ref["id"].to_i}
      end
    end
  end
end
