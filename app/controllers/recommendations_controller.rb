require "recommendation"
require "categories"

class RecommendationsController < ApplicationController
  STARTER_CATEGORY_SCORE = 10

  def show
    recommendation = ::WikiStumble::Recommendation.new(category_scores,
                                                       good_article: false)
    store_recommendation_categories(recommendation)
    @recommendation = recommendation
    @user_category_scores = category_scores
  end

  def update
    store_starter_categories
    update_category_scores
    redirect_to recommendations_show_path, status: "303"
  end

  private

  def category_scores
    session[:category_scores] ||= {}
    session[:starter_categories] ||= []
    starter_scores = session[:starter_categories]
      .map { |category| [category, STARTER_CATEGORY_SCORE] }.to_h
    session[:category_scores]
      .merge(starter_scores) do |_category, liked_score, starter_score|
      liked_score + starter_score
    end
  end

  def store_recommendation_categories(recommendation)
    session[:recommendation_categories] =
      recommendation.categories.dig("enwiki", "scores")
                    .values.first.dig("articletopic", "score", "prediction")
  end

  def store_starter_categories
    session[:starter_categories] =
      params[:categories].split(/\s*,\s*/)
                         .flat_map { |category| ::WikiStumble::Categories.from_string(category) }
  end

  def update_category_scores
    liked_increment = params[:liked].to_i || (return false)
    session[:category_scores] ||= {}
    session[:recommendation_categories].each do |category|
      session[:category_scores][category] =
      session[:category_scores].fetch(category, 0) + liked_increment
    end
  end
end
