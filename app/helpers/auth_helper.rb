module AuthHelper
  def auth_heading_classes(extra = nil)
    class_names("text-2xl font-bold text-primary", extra)
  end

  def auth_label_classes(extra = nil)
    class_names("block text-sm font-medium text-primary mb-2", extra)
  end

  def auth_input_classes(extra = nil)
    class_names("w-full px-4 py-3 rounded-lg border border-primary focus:border-accent focus:ring-2 focus:ring-accent/20 transition-colors duration-200 text-primary bg-white", extra)
  end

  def auth_primary_button_classes(extra = nil)
    class_names("w-full py-3 px-4 bg-accent-solid hover:bg-accent-600 text-solid font-medium rounded-lg transition-all duration-200 hover:shadow-lg active:scale-[0.98] cursor-pointer", extra)
  end

  def auth_secondary_button_classes(extra = nil)
    class_names("w-full py-3 px-4 border border-primary text-primary font-medium rounded-lg transition-all duration-200 hover:border-accent hover:text-accent focus:outline-none focus:ring-2 focus:ring-accent/20", extra)
  end

  def auth_link_classes(extra = nil)
    class_names("text-accent hover:text-accent-600 font-medium hover:underline transition-colors duration-200", extra)
  end
end
