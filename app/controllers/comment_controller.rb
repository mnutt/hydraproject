class CommentController < ApplicationController
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def create
    @comment = Comment.new(params[:comment])
    @comment.user_id = current_user.id
    if @comment.save
      flash[:notice] = 'Comment added.'
      redirect_to :back
    else
      redirect_to :back
    end
  end

  def update
    @comment = Comment.find(params[:id])
    if current_user.is_moderator? || (@comment.user == current_user)
      if @comment.update_attributes(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        redirect_to :back
      else
        flash[:notice] = 'Error updating comment.'
        redirect_to :back
      end
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    if current_user.is_moderator? || (@comment.user == current_user)
      @comment.destroy
      flash[:notice] = 'Comment destroyed.'
    end
    redirect_to :back
  end
  
end
