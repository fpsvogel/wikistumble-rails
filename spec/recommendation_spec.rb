require "rails_helper"

RSpec.describe "Recommendation flow", type: :system do
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