# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tasks", type: :request do
  describe "GET /tasks" do
    it "redirects to login when not authenticated" do
      get "/tasks"
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /" do
    it "returns success (root redirects to tasks or login)" do
      get "/"
      expect(response).to have_http_status(:redirect)
    end
  end
end
