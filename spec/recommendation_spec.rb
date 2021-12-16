require "rails_helper"

RSpec.describe "Recommendation page", type: :system do
  describe "starter categories field" do
    it "does not cause a cookie overflow error, instead showing an alert" do
      visit recommendations_show_path
      all_top_level_categories = "Culture, Geography, History and Society, STEM"
      find('#starter_categories').set(all_top_level_categories)
      find('input[type="submit"]').click
      expect(page).to have_selector('div.alert')
      expect(page).not_to have_selector('#recommendation')
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