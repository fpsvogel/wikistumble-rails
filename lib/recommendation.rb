require "open-uri"
require "json"
require "addressable/uri"

module WikiStumble
  class Recommendation
    attr_reader :summary, :categories, :related_articles

    def initialize(categories, good_article: false, article_count: 1)
      # TODO implement categories
      @good_article = good_article
      @article_count = article_count
      @summary, @categories = recommended_summary_and_categories
      @related_articles = related_articles(@summary)
    end

    private

    def recommended_summary_and_categories
      articles = (1..@article_count).map do
        article = random_article(good_article: @good_article)
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
    def random_article(good_article: false)
      if good_article
        random_good_article
      else
        summary_url = "https://en.wikipedia.org/api/rest_v1/page/random/summary"
        JSON.parse(URI.open(summary_url).read)
      end
    end

    def random_good_article
      redirect_url = URI("https://randomincategory.toolforge.org/Good_articles")
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