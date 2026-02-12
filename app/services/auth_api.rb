# frozen_string_literal: true

class AuthApi
  def self.base_url
    ENV.fetch("AUTH_SERVICE_URL", "http://localhost:3001")
  end

  def self.login(email, password)
    conn.post("auth/login") do |req|
      req.body = { email: email, password: password }.to_json
      req.headers["Content-Type"] = "application/json"
    end
  end

  def self.register(email, password, name = nil)
    conn.post("auth/register") do |req|
      req.body = { email: email, password: password, name: name }.to_json
      req.headers["Content-Type"] = "application/json"
    end
  end

  def self.me(token)
    conn.get("auth/me") do |req|
      req.headers["Authorization"] = "Bearer #{token}"
    end
  end

  def self.conn
    Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
