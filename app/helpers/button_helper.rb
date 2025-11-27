module ButtonHelper
  # Returns color-only classes for the soft/outline style used across the app.
  # Keeps one source of truth for bg/border/text + hover/active transitions.
  def button_soft_color_classes(color)
    case color.to_sym
    when :info
      "text-info border-info bg-info hover:bg-info-solid hover:text-solid active:bg-info-solid active:text-solid"
    when :accent
      "text-accent border-accent bg-accent hover:bg-accent-solid hover:text-solid active:bg-accent-solid active:text-solid"
    when :success
      "text-success border-success bg-success hover:bg-success-solid hover:text-solid active:bg-success-solid active:text-solid"
    when :warn
      "text-warn border-warn bg-warn hover:bg-warn-solid hover:text-solid active:bg-warn-solid active:text-solid"
    when :danger
      "text-danger border-danger bg-danger hover:bg-danger-solid hover:text-solid active:bg-danger-solid active:text-solid"
    when :neutral
      "text-neutral border-neutral bg-neutral hover:bg-neutral-solid hover:text-solid active:bg-neutral-solid active:text-solid"
    else
      "text-info border-info bg-info hover:bg-info-solid hover:text-solid active:bg-info-solid active:text-solid"
    end
  end

  # Returns color-only classes for the solid style used by the shared button.
  # Centralizes bg/text/ring/hover for consistency with semantic colors.
  def button_solid_color_classes(color)
    case color.to_sym
    when :info
      "bg-info-solid text-solid focus:ring-info-500 shadow-sm hover:shadow-md"
    when :accent
      "bg-accent-solid text-solid focus:ring-accent-500 shadow-sm hover:shadow-md"
    when :success
      "bg-success-solid text-solid focus:ring-success-500 shadow-sm hover:shadow-md"
    when :warn
      "bg-warn-solid text-solid focus:ring-warn-500 shadow-sm hover:shadow-md"
    when :danger
      "bg-danger-solid text-solid focus:ring-danger-500 shadow-sm hover:shadow-md"
    when :neutral
      "bg-neutral-solid text-solid focus:ring-neutral-500 shadow-sm hover:shadow-md"
    else
      "bg-info-solid text-solid focus:ring-info-500 shadow-sm hover:shadow-md"
    end
  end

  def button_class_pack(variant = :info)
    class_names(
      button_soft_color_classes(variant),
      "inline-block px-3 py-2 border rounded-lg cursor-pointer"
    )
  end
end
