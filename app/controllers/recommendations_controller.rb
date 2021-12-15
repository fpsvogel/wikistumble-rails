require "recommendation"
require "categories"

class RecommendationsController < ApplicationController
  def show
    recommendation = ::WikiStumble::Recommendation.new(session[:categories],
                                                       good_article: false)
    @article = recommendation.summary
    @categories = recommendation.categories
  end

  def update
    session[:categories] =
      params[:categories].split(/\s*,\s*/)
                         .map { |category| ::WikiStumble::Categories.from_string(category) }
    redirect_to recommendations_show_path, status: "303"
  end
end
