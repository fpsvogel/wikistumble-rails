require "open-uri"
require "json"

module WikiStumble
  class Recommendation
    ARTICLE_COUNT = 1

    attr_reader :title, :description, :extract, :url, :thumbnail, :categories,
                :article_type, :related_articles

    def initialize(category_scores, article_type: :any, article_count: ARTICLE_COUNT)
      # TODO implement category_scores
      @article_type = article_type.to_sym
      @article_count = article_count
      summary, @categories = recommended_summary_and_categories
      @title = summary["title"]
      @description = summary["description"]
      @extract = summary["extract"]
      @url = summary.dig("content_urls", "desktop", "page")
      @thumbnail = summary.dig("thumbnail", "source")
      @related_articles = related_articles(summary)
    end

    private

    def recommended_summary_and_categories
      articles = (1..@article_count).map do
        article = random_article(type: @article_type)
        article_id = article["revision"]
        categories = categories_for_id(article_id)
        [article, categories]
      end
      closest_match = articles[0]
      closest_match
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