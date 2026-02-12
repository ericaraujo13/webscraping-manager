# frozen_string_literal: true

class ScrapingJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task

    task.update!(status: :processing)
    result = WebmotorsScraper.new(task.url).scrape

    if result[:error]
      task.update!(
        status: :failed,
        error_message: result[:error],
        completed_at: Time.current
      )
      NotificationApi.create(
        event_type: "task_failed",
        task_id: task.id,
        user_data: { user_id: task.user_id, email: task.user_email },
        collected_data: { error: result[:error] }
      )
    else
      task.update!(
        status: :completed,
        result: { marca: result[:marca], modelo: result[:modelo], preco: result[:preco] }.compact,
        completed_at: Time.current
      )
      NotificationApi.create(
        event_type: "task_completed",
        task_id: task.id,
        user_data: { user_id: task.user_id, email: task.user_email },
        collected_data: { marca: result[:marca], modelo: result[:modelo], preco: result[:preco] }.compact
      )
    end
  end
end
