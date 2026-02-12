# frozen_string_literal: true

class TasksController < ApplicationController
  before_action :require_login
  before_action :set_task, only: [ :show, :destroy ]

  def index
    @tasks = Task.where(user_id: session[:user_id]).order(created_at: :desc)
  end

  def show
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)
    @task.user_id = session[:user_id]
    @task.user_email = session[:user_email]
    @task.status = :pending

    if @task.save
      user_data = { user_id: current_user[:id], email: current_user[:email] }
      NotificationApi.create(
        event_type: "task_created",
        task_id: @task.id,
        user_data: user_data
      )
      ScrapingJob.perform_later(@task.id)
      @task.update!(status: :processing)
      redirect_to @task, notice: "Task created. The collection will be processed soon."
    else
      render :new, status: :unprocessable_entity
    end
  rescue Faraday::Error => e
    redirect_to tasks_path, alert: "Error communicating with the notification service: #{e.message}"
  end

  def destroy
    @task.destroy
    redirect_to tasks_path, notice: "Task deleted."
  end

  private

  def set_task
    @task = Task.where(user_id: session[:user_id]).find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :url)
  end
end
