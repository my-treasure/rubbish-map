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
    @posts = Post.find(params[:id])
  end

  def new
    @posts = Post.new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
