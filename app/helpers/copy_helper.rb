module CopyHelper
  # Section heading used above card/content sections with leading icons
  def section_heading_classes
    "text-lg font-semibold text-primary mb-4 flex items-center gap-2"
  end

  # Smaller subheading used for short titles or empty-state headings
  def subheading_classes
    "mb-2 text-lg font-medium text-primary"
  end

  # Small muted helper text that appears under labels
  def hint_text_classes
    "mt-0.5 text-xs text-secondary"
  end

  # Monospace small primary text, often for field names
  def mono_label_sm_primary_classes
    "font-mono text-sm font-medium text-primary"
  end

  # Indented small muted paragraph text
  def muted_sm_indent_classes
    "ml-4 text-sm text-secondary"
  end
end
