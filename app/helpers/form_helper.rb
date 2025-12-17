module FormHelper
  def form_class_pack
    "space-y-6 max-w-2xl"
  end

  def label_classes
    "block text-sm font-medium text-primary mb-1"
  end

  def secondary_label_classes
    label_classes.sub("text-primary", "text-secondary")
  end

  def input_like_classes
    "w-full px-3 py-2 border border-primary rounded-lg text-primary bg-primary focus:outline-none focus:ring-2 focus:ring-accent focus:border-accent transition-all duration-200"
  end

  def input_classes
    "form-input #{input_like_classes}"
  end

  def checkbox_classes
    "form-checkbox size-8 mr-2 text-accent bg-primary border-primary rounded focus:ring-accent focus:ring-offset-0 focus:ring-2 transition-colors duration-200 checked:bg-accent-solid checked:hover:bg-accent-600 cursor-pointer"
  end

  def checkbox_container_classes
    "flex items-center"
  end

  def select_classes
    "form-select #{input_like_classes}"
  end

  def textarea_classes
    # Ensure visible border even when disabled
    "#{input_classes} disabled:ring-inset disabled:ring-[var(--border-primary)] disabled:ring-1"
  end

  def radio_classes
    "form-radio"
  end
end
