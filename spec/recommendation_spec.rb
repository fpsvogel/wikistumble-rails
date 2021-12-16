require "rails_helper"
require "open-uri"
require "json"

RSpec.describe "Recommendation page", type: :system do
  describe "starter categories field" do
    it "is populated with a default value at the beginning" do
      visit recommendations_show_path
      categories_default_text = find('#starter_categories').value
      expect(categories_default_text.length).to be > 0
    end

    it "continues to be shown in shorthand style after form submission" do
      visit recommendations_show_path
      # a top-level category that is shorthand for its many sub-categories.
      categories_text_before_submit = "STEM"
      find('#starter_categories').set(categories_text_before_submit)
      find('input[type="submit"]').click
      categories_text_after_submit = find('#starter_categories').value
      expect(categories_text_after_submit).to eq categories_text_before_submit
    end

    it "does not cause a cookie overflow error, instead showing an alert" do
      visit recommendations_show_path
      all_top_level_categories = "Culture, Geography, History and Society, STEM"
      find('#starter_categories').set(all_top_level_categories)
      find('input[type="submit"]').click
      expect(page).to have_selector('div.alert')
      expect(page).not_to have_selector('#recommendation')
    end
  end

  describe "article type selector" do
    it "defaults to 'Any'" do
      visit recommendations_show_path
      expect(page).to have_checked_field('article_type_any')
    end

    it "remembers the selected option after form submission" do
      visit recommendations_show_path
      choose 'article_type_good'
      find('input[type="submit"]').click
      expect(page).to have_checked_field('article_type_good')
    end

    it "shows a good article when 'Good' is selected" do
      visit recommendations_show_path
      choose 'article_type_good'
      find('input[type="submit"]').click
      article_title = find('#recommendation h2').text
      expect(article_type(article_title)).to eq :good
    end

    it "shows a featured article when 'Featured' is selected" do
      visit recommendations_show_path
      choose 'article_type_featured'
      find('input[type="submit"]').click
      article_title = find('#recommendation h2').text
      expect(article_type(article_title)).to eq :featured
    end
  end

  describe "recommended article" do
    it "is shown according to the user's category preferences" do
      visit recommendations_show_path
      categories_preference = "Geography"
      5.times do # until a short enough recommendation that doesn't fill the cookies.
        find('#starter_categories').set(categories_preference)
        find('input[type="submit"]').click
        break if find('#recommendation')
      end
      expect(page).to have_selector("#recommendation")
      article_title = find('#recommendation h2').text
      article_categories = article_categories(article_title)
      expect(article_categories.grep(/#{categories_preference}/).length).to be > 0
    end

    it "is the same after a page refresh" do
      visit recommendations_show_path
      find('input[type="submit"]').click
      original_article_title = find('h2').text
      refresh
      refreshed_article_title = find('h2').text
      expect(refreshed_article_title).to eq original_article_title
    end
  end

  private

  def article_type(article_title)
    badges_url =
      "https://www.wikidata.org/w/api.php?action=wbgetentities&format=json" \
      "&sites=enwiki&titles=#{URI::DEFAULT_PARSER.escape(article_title)}" \
      "&props=sitelinks&sitefilter=enwiki&formatversion=2"
    response = JSON.parse(URI.open(badges_url).read)
    badges = response["entities"].values.first.dig("sitelinks", "enwiki", "badges")
    if badges.include? "Q17437796"
      :featured
    elsif badges.include? "Q17437798"
      :good
    else
      :any
    end
  end

  def article_categories(article_title)
    summary_url = "https://en.wikipedia.org/api/rest_v1/page/summary/#{URI::DEFAULT_PARSER.escape(article_title)}"
    summary = JSON.parse(URI.open(summary_url).read)
    revision_id = summary["revision"]
    categories_url =
      "https://ores.wikimedia.org/v3/scores/enwiki/?models=articletopic&revids=#{revision_id}"
    categories = JSON.parse(URI.open(categories_url).read)
    categories.dig("enwiki", "scores")
              .values.first.dig("articletopic", "score", "prediction")
  end
end