# frozen_string_literal: true

class BrowserFetcher
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"

  def self.enabled?
    true
  end

  def self.fetch(url)
    new(url).fetch
  end

  def initialize(url)
    @url = url
  end

  def fetch
    driver = create_driver
    driver.manage.timeouts.page_load = 45
    driver.navigate.to(@url)
    simulate_reading(driver)
    sleep 2
    html = driver.page_source
    driver.quit

    html.present? ? html : { error: "Empty HTML returned" }
  rescue StandardError => e
    driver&.quit
    Rails.logger.error "BrowserFetcher error: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    { error: "Browser: #{e.class.name} - #{e.message}" }
  end

  private

  def create_driver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--user-agent=#{USER_AGENT}")
    options.add_argument("--lang=pt-BR")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--no-sandbox")
    # options.add_argument("--headless=new")
    Selenium::WebDriver.for :chrome, options: options
  end

  def simulate_reading(driver)
    driver.execute_script("window.scrollTo(0, 400)")
    sleep(0.5 + rand(0.5))
    driver.execute_script("window.scrollTo(0, 0)")
    sleep(0.3 + rand(0.4))
  rescue StandardError => _e
  end
end
