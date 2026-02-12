# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    @error = nil
  end

  def create
    resp = AuthApi.login(params[:email], params[:password])
    if resp.success?
      data = resp.body
      session[:auth_token] = data["token"]
      session[:user_id] = data["user"]["id"]
      session[:user_email] = data["user"]["email"]
      session[:user_name] = data["user"]["name"]
      redirect_to tasks_path, notice: "You are logged in."
    else
      @error = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  rescue Faraday::Error => e
    @error = "Authentication service unavailable. Try again."
    render :new, status: :unprocessable_entity
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "You are logged out."
  end
end
