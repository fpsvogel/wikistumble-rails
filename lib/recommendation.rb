require "open-uri"
require "json"

module WikiStumble
  class Recommendation
    MAX_ARTICLE_QUERIES = 10
    CANDIDATE_CHANCE = 2 # multiplied by the ratio (candidate_score / top user
    # category score), to get a probability that a candidate will be selected
    # early, before max_article_queries is reached.

    attr_reader :title, :description, :extract, :url, :thumbnail_source,
                :categories, :article_type, :related_articles

    def initialize(user_category_scores,
                   article_type: :any,
                   max_article_queries: MAX_ARTICLE_QUERIES,
                   candidate_chance: CANDIDATE_CHANCE)
      @article_type = article_type.to_sym
      @max_article_queries = max_article_queries
      @candidate_chance = candidate_chance
      summary, @categories, _candidate_score =
        recommended_summary_and_categories(user_category_scores)
      @title = summary["title"]
      @description = summary["description"]
      @extract = summary["extract"]
      @url = summary.dig("content_urls", "desktop", "page")
      @thumbnail_source = summary.dig("thumbnail", "source")
      @related_articles = related_articles(summary)
    end

    def simple_categories
      from_categories_response(categories, "prediction")
    end

    private

    def recommended_summary_and_categories(user_category_scores)
      candidates = []
      (1..@max_article_queries).each do |query_n|
        article = random_article(type: @article_type)
        article_id = article["revision"]
        article_categories = categories_for_id(article_id)
        score = candidate_score(article_categories, user_category_scores)
        candidates << [article, article_categories, score]
        if good_enough_candidate?(score, user_category_scores)
          Rails.logger.info "GOOD ENOUGH CANDIDATE after #{query_n} queries, score #{score}"
          return candidates.last
        end
      end
      candidates.max_by(&:last)
    end

    def candidate_score(categories_response, category_scores)
      top_categories = categories_prediction(categories_response)
      probabilities = categories_probability(categories_response)
      top_categories.map do |category|
        probabilities[category] * (category_scores[category] || 0)
      end.sum
    end

    def good_enough_candidate?(score, user_category_scores)
      return false if score < 0
      top_category_score = user_category_scores.max_by { |_category, score| score }.last
      probability = @candidate_chance * (score / top_category_score)
      probability > 1 || rand < probability
    end

    def categories_prediction(categories_response)
      from_categories_response(categories_response, "prediction")
    end

    def categories_probability(categories_response)
      from_categories_response(categories_response, "probability")
    end

    def from_categories_response(categories_response, key)
      categories_response.dig("enwiki", "scores")
                         .values.first.dig("articletopic", "score", key)
    end

    def categories_for_id(article_id)
      # from https://stackoverflow.com/a/65801715/4158773
      # list of topics: https://www.mediawiki.org/wiki/ORES/Articletopic
      categories_url =
        "https://ores.wikimedia.org/v3/scores/enwiki/?models=articletopic&revids=#{article_id}"
      JSON.parse(URI.open(categories_url).read)
    end

    # Wikipedia REST API documentation: https://en.wikipedia.org/api/rest_v1/#/Page%20content
    def random_article(type: :any)
      case type
      when :good
        random_x_article("Good_articles")
      when :featured
        random_x_article("Featured_articles")
      else
        summary_url = "https://en.wikipedia.org/api/rest_v1/page/random/summary"
        JSON.parse(URI.open(summary_url).read)
      end
    end

    def random_x_article(query_string)
      redirect_url = URI("https://randomincategory.toolforge.org/#{query_string}")
      redirect = Net::HTTP.get_response(redirect_url)
      article_url = redirect["location"]
      title = article_url.split("/").last
      summary_url = "https://en.wikipedia.org/api/rest_v1/page/summary/#{escape(title)}"
      JSON.parse(URI.open(summary_url).read)
    end

    def related_articles(summary)
      JSON.parse(URI.open("https://en.wikipedia.org/api/rest_v1/page/related/#{escape(@title)}").read)
    rescue OpenURI::HTTPError
      Rails.logger.error "Unable to get related articles for \"#{@title}\" #{@url}"
      nil
    end

    def escape(title)
      URI::DEFAULT_PARSER.escape(title)
    end
  end
end