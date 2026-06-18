Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do
    resources :lists, only: [:index, :create, :destroy]
  end
end
