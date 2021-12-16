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
  end

  describe "recommended article" do
    it "is the same after a page refresh" do
      visit recommendations_show_path
      find('input[type="submit"]').click
      original_article_title = find('h2').text
      refreshed_article_title = find('h2').text
      expect(refreshed_article_title).to eq original_article_title
    end
  end
end