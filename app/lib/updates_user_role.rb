class UpdatesUserRole
  def update(actor:, user:, admin_demotion:, confirmation: nil)
    if !actor.admin?
      Outcome.failure("Only administrators can modify user roles.")
    elsif (confirmation_error = invalid_demotion_confirmation(actor:, user:, admin_demotion:, confirmation:))
      Outcome.failure(confirmation_error)
    else
      update_role(user: user, admin_demotion:)
    end
  end

  private

  def invalid_demotion_confirmation(actor:, user:, admin_demotion:, confirmation:)
    if admin_demotion && actor == user
      confirmation = confirmation.to_s.strip.downcase
      if confirmation.blank?
        "Please enter #{user.email} to confirm demotion."
      elsif user.email != confirmation
        "Email confirmation must match #{user.email}."
      end
    end
  end

  def success_message(user, admin)
    if admin
      "#{user.email} is now an administrator."
    else
      "#{user.email} is now a standard user."
    end
  end

  def update_role(user:, admin_demotion:)
    return Outcome.success(success_message(user, !admin_demotion)) if user.admin? == !admin_demotion

    User.transaction do
      admins = User.where(admin: true).lock.to_a
      user.lock!
      admins_excluding_user = admins.reject { |u| u.id == user.id }
      other_users_exist = User.where.not(id: user.id).exists?

      if admin_demotion && admins_excluding_user.empty? && other_users_exist
        Outcome.failure("At least one user must be an admin")
      else
        save_role(user:, admin: !admin_demotion)
      end
    end
  end

  def save_role(user:, admin:)
    user.admin = admin
    if user.save
      Outcome.success(success_message(user, admin))
    else
      Outcome.failure(user.errors.full_messages.join(", "))
    end
  end
end
