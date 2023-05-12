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
      photo_url = @post.photo.service_url
      @post.update(post_image: photo_url)
      #redirect_to @post
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

  private

  def post_params
    params.require(:post).permit(:title, :body, :address, :photo)
  end
end
