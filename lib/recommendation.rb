require "open-uri"
require "json"

module WikiStumble
  class Recommendation
    # TODO: instead of querying for this many articles and then finding the best
    # match to the user's category scores, it would be faster to query *up to*
    # this many but break as soon as an acceptably good match is found. this
    # would also prevent the user from seeing articles of the same category
    # every time (their top-scored category). but what is an "acceptably good
    # match"? it seems it would depend on how far along the user is in their
    # scoring.
    ARTICLE_CANDIDATES = 10

    attr_reader :title, :description, :extract, :url, :thumbnail, :categories,
                :article_type, :related_articles

    def initialize(user_category_scores,
                   article_type: :any,
                   article_candidates: ARTICLE_CANDIDATES)
      @article_type = article_type.to_sym
      @article_candidates_count = article_candidates
      summary, @categories, _match_score =
        recommended_summary_and_categories(user_category_scores)
      @title = summary["title"]
      @description = summary["description"]
      @extract = summary["extract"]
      @url = summary.dig("content_urls", "desktop", "page")
      @thumbnail = summary.dig("thumbnail", "source")
      @related_articles = related_articles(summary)
    end

    def simple_categories
      from_categories_response(categories, "prediction")
    end

    private

    def recommended_summary_and_categories(user_category_scores)
      candidates = (1..@article_candidates_count).map do
        article = random_article(type: @article_type)
        article_id = article["revision"]
        categories = categories_for_id(article_id)
        [article, categories]
      end
      best_match(candidates, user_category_scores)
    end

    def best_match(candidates, user_category_scores)
      candidates.map do |article, candidate_categories|
        score = match_score(candidate_categories, user_category_scores)
        [article, candidate_categories, score]
      end.max_by(&:last)
    end

    def match_score(categories_response, category_scores)
      top_categories = categories_prediction(categories_response)
      probabilities = categories_probability(categories_response)
      top_categories.map do |category|
        probabilities[category] * (category_scores[category] || 0)
      end.sum
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
      puts "RANDOM #{query_string.upcase}"
      redirect_url = URI("https://randomincategory.toolforge.org/#{query_string}")
      redirect = Net::HTTP.get_response(redirect_url)
      article_url = redirect["location"]
      title = article_url.split("/").last
      summary_url = "https://en.wikipedia.org/api/rest_v1/page/summary/#{escape(title)}"
      JSON.parse(URI.open(summary_url).read)
    end

    def related_articles(summary)
      title = summary["title"]
      JSON.parse(URI.open("https://en.wikipedia.org/api/rest_v1/page/related/#{escape(title)}").read)
    end

    def escape(title)
      URI::DEFAULT_PARSER.escape(title)
    end

    # RM probably unneeded:
    # get all categories of an article: "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=categories&titles=Google&clshow=!hidden&cllimit=100"
    # top-level categories: https://en.wikipedia.org/wiki/Category:Main_topic_classifications
  end
end