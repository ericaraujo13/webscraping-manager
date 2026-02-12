# frozen_string_literal: true

class NotificationApi
  def self.base_url
    ENV.fetch("NOTIFICATION_SERVICE_URL", "http://localhost:3002")
  end

  def self.create(event_type:, task_id:, user_data:, collected_data: {})
    Faraday.post("#{base_url}/notifications") do |req|
      req.body = {
        event_type: event_type,
        task_id: task_id,
        user_data: user_data,
        collected_data: collected_data
      }.to_json
      req.headers["Content-Type"] = "application/json"
    end
  end

  def self.conn
    Faraday.new(url: base_url) do |f|
      f.adapter Faraday.default_adapter
    end
  end
end
