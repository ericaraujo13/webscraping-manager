# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  describe "validations" do
    it "is valid with url and user_id (valid advertisement URL)" do
      task = Task.new(
        url: "https://www.webmotors.com.br/carros/comprar/ford/ka/12345",
        user_id: 1
      )
      expect(task).to be_valid
    end

    it "is invalid without url" do
      task = Task.new(user_id: 1)
      expect(task).not_to be_valid
      expect(task.errors[:url]).to be_present
    end

    it "is invalid without user_id" do
      task = Task.new(url: "https://www.webmotors.com.br/carros/comprar/ford/ka/12345")
      expect(task).not_to be_valid
      expect(task.errors[:user_id]).to be_present
    end

    it "rejects listing page URL" do
      task = Task.new(
        url: "https://www.webmotors.com.br/carros/ford/ka",
        user_id: 1
      )
      expect(task).not_to be_valid
      expect(task.errors[:url]).to be_present
    end
  end

  describe "#status_label" do
    it "returns label for status" do
      task = Task.new(status: "pending")
      expect(task.status_label).to eq("Pendente")
    end
  end
end
