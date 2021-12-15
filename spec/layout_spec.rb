require "rails_helper"

RSpec.describe "Site layout", type: :system do
  describe "home page" do
    it "has a footer" do
      visit recommendations_show_path
      expect(page).to have_selector('#footer')
    end
  end
end