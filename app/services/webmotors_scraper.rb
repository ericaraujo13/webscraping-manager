# frozen_string_literal: true

require "nokogiri"

class WebmotorsScraper
  KEYS = %i[marca modelo preco]

  VEHICLE_SECTION_SELECTORS = [
    "[class*='VehicleDetail']",
    "[class*='vehicle-detail']",
    "[class*='ListingDetail']",
    "[class*='listing-detail']",
    "[class*='DetailPage']",
    "[class*='AdDetail']",
    "[class*='ad-detail']",
    "[data-vehicle-id]",
    "main",
    "[role='main']"
  ].freeze

  def initialize(url)
    @url = url
  end

  def scrape
    doc = fetch_page
    return { error: doc[:error] } if doc.is_a?(Hash)
    return { error: "Unable to access the page" } unless doc

    section = vehicle_section(doc)
    json_ld = extract_from_json_ld(doc)
    from_section = extract_from_section(section)
    result = from_section.merge(json_ld)
    result.slice!(*KEYS)
    result.compact.presence || { error: "Advertisement data not found on the page" }
  end

  private

  def fetch_page
    html = BrowserFetcher.fetch(@url)
    return html if html.is_a?(Hash)
    return { error: "Unable to load the page" } if html.blank?
    Nokogiri::HTML(html)
  rescue StandardError => e
    { error: e.message }
  end

  def extract_from_json_ld(doc)
    doc.css('script[type="application/ld+json"]').each do |script|
      data = normalize_ld(JSON.parse(script.text))
      next unless data.is_a?(Hash) && (data["@type"]&.include?("Car") || data["name"])
      return {
        marca: data["brand"]&.dig("name") || data["brand"]&.to_s || data["name"]&.split(/\s+/)&.first,
        modelo: data["name"]&.to_s || data["model"]&.to_s,
        preco: parse_price(data["offers"]&.dig("price") || data["price"])
      }.compact
    end
    {}
  rescue JSON::ParserError
    {}
  end

  def normalize_ld(data)
    data = data["@graph"]&.find { |n| n["@type"] == "Car" } if data.is_a?(Hash) && data["@graph"]
    data.is_a?(Array) ? data.first : data
  end

  def parse_price(val)
    return nil if val.blank?
    s = val.to_s.gsub(/[^\d,.]/, "").strip
    return nil if s.blank?
    s = s.include?(",") ? s.delete(".").tr(",", ".") : (s.split(".").last.length == 3 ? s.delete(".") : s)
    Float(s)
  rescue ArgumentError
    nil
  end

  def vehicle_section(doc)
    return doc unless doc
    VEHICLE_SECTION_SELECTORS.each do |sel|
      node = doc.at_css(sel)
      return node if node
    end
    doc
  end

  def extract_from_section(section)
    return {} unless section
    price_el = section.at_css("[data-price], .price__value, .vehicle-price, [class*='price'], [class*='Price']")
    title_el = section.at_css("h1, [class*='vehicle-name'], [class*='VehicleName'], [class*='title']")
    title_text = title_el&.text&.strip
    result = {}
    result[:preco] = price_el && parse_price(price_el["data-price"] || price_el.text)
    if title_text.present?
      tokens = title_text.split(/\s+/)
      result[:marca] = tokens.first
      result[:modelo] = tokens[1..].join(" ") if tokens.size > 1
    end
    result.compact
  end
end
