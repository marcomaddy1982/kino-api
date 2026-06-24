Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do
    resources :lists, only: [:index, :create, :destroy] do
      resources :list_items, only: [:index, :create, :destroy], path: "items"
    end
    namespace :favourites do
      resources :items, only: [:show], param: :tmdb_movie_id
      post "items/:tmdb_movie_id/toggle", to: "items#toggle", as: :toggle_item
    end
  end
end
