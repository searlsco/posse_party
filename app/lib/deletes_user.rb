class DeletesUser
  def delete(actor:, user:)
    return Outcome.failure("Only administrators can delete other users.") if non_admin_deleting_others?(actor: actor, user: user)

    User.transaction do
      admins = User.where(admin: true).lock.to_a
      other_users_exist = User.where.not(id: user.id).exists?
      last_admin = user.admin? && admins.none? { |u| u.id != user.id } && other_users_exist

      if last_admin
        Outcome.failure("At least one administrator must remain so long as any non-admin users exist.")
      else
        user.lock!
        perform_deletion(user)
      end
    end
  end

  private

  def non_admin_deleting_others?(actor:, user:)
    actor != user && !actor.admin?
  end

  def admin_would_orphan_users?(user:)
    return false unless user.admin?
    return false if only_user?(user)

    User.where(admin: true).where.not(id: user.id).blank?
  end

  def only_user?(user)
    User.where.not(id: user.id).blank?
  end

  def perform_deletion(user)
    user_with_associations = User.includes(
      accounts: :crossposts,
      feeds: {posts: :crossposts}
    ).find(user.id)

    if user_with_associations.destroy
      Outcome.success("User deleted successfully.")
    else
      Outcome.failure("Failed to delete user", user_with_associations.errors.full_messages.join(", "))
    end
  end
end
