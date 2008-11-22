class CategoriesController < ApplicationController
  def show
    @category = Category.find(params[:id])
    @torrents = @category.torrents.paginate(:page => params[:page])
  end
end
