class ConfirmsUserDeletion
  def initialize(deletes_user: DeletesUser.new)
    @deletes_user = deletes_user
  end

  def delete(actor:, user:, email_confirmation:)
    return Outcome.failure("You must be signed in to delete this user.") if actor.nil?

    expected_email = user.email
    confirmation = email_confirmation.to_s.strip

    if confirmation.blank?
      return Outcome.failure("Please enter #{expected_email} to confirm deletion.")
    end

    unless confirmation.casecmp?(expected_email)
      return Outcome.failure("Email confirmation must match #{expected_email}.")
    end

    @deletes_user.delete(actor: actor, user: user)
  end
end
