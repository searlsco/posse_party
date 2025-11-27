module Notifications
  class PreloadsRefs
    ALLOWED_MODELS = %w[Post Crosspost Account Feed].freeze
    def preload(refs)
      groups = Hash.new { |h, k| h[k] = [] }
      Array(refs).each do |ref|
        model = ref.is_a?(Hash) ? ref["model"] : nil
        id = ref.is_a?(Hash) ? ref["id"] : nil
        groups[model] << id if model.present? && id.present? && ALLOWED_MODELS.include?(model)
      end

      loaded = {}
      groups.each do |model, ids|
        klass = model.constantize
        records = klass.where(id: ids.uniq).to_a
        loaded[model] = records.index_by(&:id)
      rescue NameError
      end
      loaded
    end
  end
end
