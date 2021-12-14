require "rails_helper"

RSpec.describe "Site layout", type: :system do
  describe "layout" do
    it "has a footer" do
      visit root_path
      expect(page).to have_selector('#footer')
    end
  end
end