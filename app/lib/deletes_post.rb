class DeletesPost
  def delete(post)
    Post.transaction do
      # Lock all related crossposts so status can't change during deletion
      locked_crossposts = Crosspost.where(post_id: post.id).lock.to_a

      if locked_crossposts.any?(&:wip?)
        return Outcome.failure("Cannot delete post while one or more crossposts are in progress (WIP). Please wait or skip them first.")
      else
        # Eager load associations to satisfy strict_loading during dependent destroys
        post_with_associations = Post.includes(:crossposts).find(post.id)

        if post_with_associations.destroy
          Outcome.success("Post deleted successfully.")
        else
          Outcome.failure("Failed to delete post: #{post_with_associations.errors.full_messages.to_sentence}")
        end
      end
    end
  end
end
