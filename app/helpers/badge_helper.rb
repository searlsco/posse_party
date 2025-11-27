module BadgeHelper
  def badge_dot_classes(active: false, context: :generic)
    size = case context
    when :sidebar then "w-2.5 h-2.5 lg:w-3 lg:h-3"
    else "w-3.5 h-3.5"
    end

    offset = case context
    when :sidebar
      "-top-[3px] -right-[2px]"
    else
      "-top-[5px] -right-[4px]"
    end

    color = if context == :sidebar && active
      "bg-[currentColor] ring-1 ring-white/30 dark:ring-black/30"
    else
      "bg-gradient-to-br from-red-500 via-red-600 to-red-700 opacity-70 shadow-sm ring-1 ring-white/40 dark:ring-black/20"
    end

    ["absolute rounded-full", offset, size, color].join(" ")
  end
end
