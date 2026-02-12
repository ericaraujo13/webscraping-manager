# frozen_string_literal: true

class Task < ApplicationRecord
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  STATUS_LABELS = {
    pending: "Pendente",
    processing: "Processando",
    completed: "Concluída",
    failed: "Falha"
  }.freeze

  validates :url, presence: true
  validates :user_id, presence: true
  validate :validate_advertisement_url

  def status_label
    STATUS_LABELS[status&.to_sym] || status
  end

  private

  def validate_advertisement_url
    return if url.blank?
    uri = parse_uri
    return errors.add(:url, "is not a valid URL") unless uri
    return unless listing_page?(uri.path)
    errors.add(:url, "must be an individual advertisement (link when clicking on a car). Listing/search pages are not supported.")
  end

  def parse_uri
    uri = URI.parse(url)
    uri if uri.is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    nil
  end

  def listing_page?(path)
    return false unless path.include?("/carros/")

    !path.include?("/comprar/") && !path.split("/").last.match?(/\A\d+\z/)
  end
end
