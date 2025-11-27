module CardHelper
  def card_wrapper_classes(clickable:, hover:, padding_class:, layout_class:, presentation_override:, background_class:, hover_background_class: nil)
    merge_classes(
      base_classes,
      interaction_classes(clickable),
      presentation_classes(clickable, presentation_override, background_class),
      hover_classes(clickable, hover, hover_background_class),
      padding_class,
      layout_class
    )
  end

  # Reusable title/label text classes for card headers (used by >2 card partials)
  def card_title_text_classes(clickable:, enable_hover_accent: false)
    merge_classes(
      %w[text-lg font-semibold text-primary],
      (clickable && enable_hover_accent) ? %w[group-hover:text-accent transition-colors duration-200] : []
    )
  end

  # Standard icon container used in compact cards (post/feed, etc.)
  def card_icon_box_classes
    "size-10 rounded-lg bg-accent/10 flex items-center justify-center flex-shrink-0"
  end

  # Pill-style chip container used for inline badges/status
  def chip_classes
    "inline-flex items-center gap-2 px-3 py-1 rounded-full border border-primary bg-primary/30"
  end

  def base_classes
    %w[relative rounded-xl overflow-hidden]
  end

  def interaction_classes(clickable)
    clickable ? %w[cursor-pointer border border-accent shadow-sm] : ["border"]
  end

  def presentation_classes(clickable, presentation_override, background_class)
    return Array(presentation_override) if presentation_override.present?

    if clickable
      [background_class.presence || default_clickable_background]
    else
      ["border-primary bg-primary shadow-sm"]
    end
  end

  def hover_classes(clickable, hover, hover_background_class)
    return [] unless hover

    classes = ["transition-all duration-500 hover:shadow-md hover:-translate-y-0.5"]
    if clickable
      classes << (hover_background_class.presence || default_clickable_hover_background)
    end
    classes
  end

  def default_clickable_background
    "bg-gradient-to-br from-primary via-primary to-accent-50 dark:from-primary dark:via-primary dark:to-accent-900"
  end

  def default_clickable_hover_background
    "hover:from-accent-50 hover:via-accent-100 hover:to-accent-200 dark:hover:from-accent-900 dark:hover:via-accent-800 dark:hover:to-accent-700"
  end

  def merge_classes(*parts)
    parts
      .flatten
      .compact
      .map { |part| part.to_s.strip }
      .compact_blank
      .join(" ")
  end
end
