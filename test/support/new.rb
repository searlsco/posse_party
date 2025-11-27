module New
  @sequence = 0

  MINIMAL_ATTRS = {
    User => ->(attrs) {
      name = "user-#{@sequence += 1}"

      {
        email: "#{name}@example.com",
        api_key: SecureRandom.hex(32),
        admin: false,
        password: "Password!#{@sequence}",
        password_confirmation: "Password!#{@sequence}"
      }
    },
    Account => ->(attrs) {
      name = "handle_#{@sequence += 1}"

      {
        user: attrs.fetch(:user) { New.new(User) },
        platform_tag: "bsky",
        label: "@#{name}",
        credentials: {
          "email" => "#{name}@example.com",
          "password" => "password"
        }
      }
    },
    Feed => ->(attrs) {
      name = "feed-#{@sequence += 1}"

      {
        user: attrs.fetch(:user) { New.new(User) },
        label: name,
        url: "http://example.com/#{name}.xml"
      }
    },
    Post => ->(attrs) {
      slug = "slug-#{@sequence += 1}"
      url = "http://example.com/#{slug}"
      {
        feed: attrs.fetch(:feed) { New.new(Feed) },
        url: url,
        remote_id: "{#{slug}}",
        remote_updated_at: Now.time,
        remote_published_at: Now.time,
        alternate_url: url,
        author_name: "An Author",
        author_email: "author-#{@sequence}@example.com",
        title: "What's the deal with airline food?",
        summary: "It's not very good.",
        content: "Boy do I hate airline food."
      }
    }
  }

  AFTER_NEW_HOOKS = {
    Post => ->(post, attrs) {
      # Do stuff
    }
  }

  def self.new(klass, **attrs)
    ensure_valid_attrs!(klass, attrs)

    klass.new(**combine_attrs(klass, attrs)).tap do |instance|
      AFTER_NEW_HOOKS[klass]&.call(instance, attrs)
    end
  end

  def self.create(klass, **attrs)
    new(klass, __method_called: :create, **attrs).tap { |m| m.save! }
  end

  def self.create_without_validation(klass, **attrs)
    new(klass, __method_called: :create, **attrs).tap { |m|
      m.save!(validate: false)
    }
  end

  def self.ensure_valid_attrs!(klass, attrs)
    supported_attrs = klass.attribute_names + klass.reflect_on_all_associations.map { |assoc| assoc.name.to_s }
    if (bad_attrs = filter_ar_attrs(attrs).keys.map(&:to_s) - supported_attrs).present?
      raise "Attributes #{bad_attrs} are not available on #{klass.name}.\n\nSupported attributes:\n  #{supported_attrs.join("\n  ")}"
    end
  end

  def self.combine_attrs(klass, attrs)
    minimal_attrs = if (minimal_attrs_proc = MINIMAL_ATTRS[klass])
      if minimal_attrs_proc.arity == 1
        minimal_attrs_proc.call(attrs)
      else
        minimal_attrs_proc.call
      end
    else
      {}
    end

    minimal_attrs.merge(filter_ar_attrs(attrs))
  end

  def self.filter_ar_attrs(attrs)
    attrs.reject { |k, v| k.to_s.start_with?("__") }.to_h
  end
end
