require "recommendation"
require "categories"

class RecommendationsController < ApplicationController
  STARTER_CATEGORY_SCORE = 10

  def show
    @user_category_scores = category_scores.sort_by { |_category, score| -score }
                                             .to_h
    @starter_categories = session[:starter_categories_string] ||
                          ::WikiStumble::Categories::DEFAULT_STRING
    @article_type = session[:article_type]&.to_sym || :any
    @recommendation = session[:recommendation]
  end

  def update
    store_starter_categories
    store_article_type
    add_like_or_dislike_into_category_scores
    get_and_store_recommendation
    redirect_to recommendations_show_path, status: "303"
  end

  private

  def preferences_submitted?
    session.has_key?(:starter_categories)
  end

  def category_scores
    session[:category_scores] ||= {}
    starter_scores = (session[:starter_categories] || {})
      .map { |category| [category, STARTER_CATEGORY_SCORE] }.to_h
    session[:category_scores]
      .merge(starter_scores) do |_category, liked_score, starter_score|
      liked_score + starter_score
    end
  end

  def store_article_type
    session[:article_type] = params[:article_type]
  end

  def store_starter_categories
    session[:starter_categories_string] = params[:starter_categories]
    session[:starter_categories] =
      ::WikiStumble::Categories.from_string(params[:starter_categories])
  end

  def add_like_or_dislike_into_category_scores
    liked_increment = Integer(params[:liked], exception: false) || (return false)
    session[:category_scores] ||= {}
    (session[:recommendation_categories] || []).each do |category|
      session[:category_scores][category] =
      session[:category_scores].fetch(category, 0) + liked_increment
    end
  end

  def get_and_store_recommendation
    recommendation =
      ::WikiStumble::Recommendation.new(category_scores,
                                        article_type: session[:article_type])
    store_recommendation_categories(recommendation)
    session[:recommendation] =
      {
        title: recommendation.title,
        description: recommendation.description,
        url: recommendation.url,
        extract: recommendation.extract,
        thumbnail_source: recommendation.thumbnail_source
      }
  end

  def store_recommendation_categories(recommendation)
    session[:recommendation_categories] = recommendation.simple_categories
  end
end
