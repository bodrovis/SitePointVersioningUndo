class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :history, :show]

  def history
    @versions = PaperTrail::Version.order('created_at DESC')
  end

  def undo
    @post_version = PaperTrail::Version.find_by_id(params[:id])

    begin
      if @post_version.reify
        @post_version.reify.save
      else
        # For undoing the create action
        @post_version.item.destroy
      end
      flash[:success] = "Undid that! #{make_redo_link}"
    rescue
      flash[:alert] = "Failed undoing the action..."
    ensure
      redirect_to root_path
    end
  end

  def index
    @posts = Post.all
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      flash[:success] = "Post was created! #{make_undo_link}"
      redirect_to post_path(@post)
    else
      render 'new'
    end
  end

  def show
    @post = Post.find_by_id(params[:id])
  end

  def edit
    @post = Post.find_by_id(params[:id])
  end

  def update
    @post = Post.find_by_id(params[:id])
    if @post.update_attributes(post_params)
      flash[:success] = "Post was updated! #{make_undo_link}"
      redirect_to post_path(@post)
    else
      render 'edit'
    end
  end

  def destroy
    @post = Post.find_by_id(params[:id])
    if @post.destroy
      flash[:success] = "Post was destroyed! #{make_undo_link}"
    else
      flash[:alert] = 'Error while desroying the post!'
    end
    redirect_to root_url
  end

  private

  def post_params
    params.require(:post).permit(:body, :title)
  end

  def make_undo_link
    view_context.link_to 'Undo that plz!', undo_path(@post.versions.last), method: :post
  end

  def make_redo_link
    params[:redo] == "true" ? link = "Undo that plz!" : link = "Redo that plz!"
    view_context.link_to link, undo_path(@post_version.next, redo: !params[:redo]), method: :post
  end
end