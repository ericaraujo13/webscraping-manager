# frozen_string_literal: true

class RegistrationsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]

  def new
    @user = {}
    @errors = []
  end

  def create
    resp = AuthApi.register(params[:email], params[:password], params[:name])
    if resp.success?
      redirect_to login_path, notice: "Account created. Please login."
    else
      body = resp.body.is_a?(Hash) ? resp.body : {}
      @errors = body["errors"] || [ "Unable to create the account." ]
      @user = { email: params[:email], name: params[:name] }
      render :new, status: :unprocessable_entity
    end
  rescue Faraday::Error
    @errors = [ "Authentication service unavailable. Try again." ]
    render :new, status: :unprocessable_entity
  end
end
