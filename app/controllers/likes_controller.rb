class LikesController < ApplicationController

  def create
    user = current_user
    post = Post.find(params[:post_id])
    like = Like.create(post_id: post, user_id: user)
    redirect_to post_path(post)
  end

  private

  def find_post
    @post = Post.find(params[:post_id])
  end

end
