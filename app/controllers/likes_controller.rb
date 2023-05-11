class LikesController < ApplicationController

  def create
    @post.likes.create(user_id: current_user.id)
    redirect_to post_path(@post)
  end

  private

  def find_post
    @post = Post.find(params[:post_id])
  end

end
