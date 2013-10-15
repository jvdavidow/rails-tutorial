class VotesController < ApplicationController
  before_filter :setup

  def up_vote
    update_vote(1)
    
    # no flash message, just want it to "happen"
    redirect_to :back
  end

  def down_vote
    update_vote(-1)
    
    # no flash message, just want it to "happen"
    redirect_to :back
  end

  private

  def setup
    @topic = Topic.find(params[:topic_id])
    @post = @topic.posts.find(params[:post_id])
    authorize! :create, Vote, message: "You need to be a user to do that."

    @vote = @post.votes.where(user_id: current_user.id).first
  end

  def update_vote(new_value)
    logger.debug("update_vote")
    if @vote # if it exists, update it
      logger.debug("exists")
      @vote.update_attribute(:value, new_value)
    else # create it
      logger.debug("doesn't exist")
      @vote = current_user.votes.create(value: new_value, post: @post)
    end
  end

end
