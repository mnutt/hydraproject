class CategoriesController < ApplicationController
  before_filter :authorize_view

  def show
    @category = Category.find(params[:id])
    @torrents = @category.torrents.paginate(:page => params[:page])
  end
end
