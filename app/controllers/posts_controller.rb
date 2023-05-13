class PostsController < ApplicationController
  def index
    @posts = Post.all

    @markers = @posts.geocoded.map do |post|
      {
        lat: post.latitude,
        lng: post.longitude,
        info_window_html: render_to_string(partial: "info_window", locals: { post: post }),
        marker_html: render_to_string(partial: "marker", locals: { post: post })
      }
    end
  end

  def show
    @post = Post.find(params[:id])
    @markers =
      {
        lat: @post.latitude,
        lng: @post.longitude,
        info_window_html: render_to_string(partial: "info_window", locals: { post: @post }),
        marker_html: render_to_string(partial: "marker", locals: { post: @post })
      }
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @user = current_user
    @post.user = @user

    if @post.save

      redirect_to root_path

    else
      render :new
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  def like
    post = Post.fine(params[:id])
    Like.create(user: current_user, post:)
  end

  def unlike
    post = Post.find(params[:id])
    raise
    post.likes.delete(current_user)
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :address, :post_image)
  end
end
