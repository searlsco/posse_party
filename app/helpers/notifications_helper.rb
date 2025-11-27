module NotificationsHelper
  def notification_icon(severity)
    {"success" => "check_circle", "warn" => "exclamation_triangle", "danger" => "exclamation_circle"}[severity.to_s] || "information_circle"
  end

  def linkify_notification_text(text)
    return "" if text.blank?
    escaped = ERB::Util.html_escape(text.to_s)
    url_regex = %r{https?://[^\s<]+}
    linked = escaped.gsub(url_regex) do |url|
      link_to(url, url, target: "_blank", rel: "noopener", class: "text-accent hover:underline break-all")
    end
    linked.html_safe
  end
end
