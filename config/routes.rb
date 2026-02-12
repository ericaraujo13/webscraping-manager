require "sidekiq/web"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "register", to: "registrations#new"
  post "register", to: "registrations#create"

  # UI do Sidekiq (apenas usuários logados)
  constraints(->(req) { req.session[:auth_token].present? }) do
    mount Sidekiq::Web => "/sidekiq"
  end

  root "tasks#index"
  resources :tasks, only: [:index, :show, :new, :create, :destroy]
end
