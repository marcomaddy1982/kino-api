Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  get "/docs/openapi.yml", to: proc { [ 200, { "Content-Type" => "application/yaml" }, [ File.read(Rails.root.join("docs/openapi.yml")) ] ] }

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do
    namespace :auth do
      post :register, to: "sessions#register"
      post :login,    to: "sessions#login"
      post :refresh,  to: "sessions#refresh"
      delete :logout, to: "sessions#logout"
    end
    resources :lists, only: [ :index, :create, :destroy ], controller: "lists/lists" do
      resources :list_items, only: [ :index, :create, :destroy ], path: "items", controller: "lists/items"
    end

    resources :movies, only: [ :index, :show ], controller: "movies/movies" do
      get :search, on: :collection
    end
    get    "calendar",                              to: "calendar/entries#index"
    post   "calendar/entries",                      to: "calendar/entries#create"
    patch  "calendar/entries/:id",                  to: "calendar/entries#update"
    delete "calendar/entries/:id",                  to: "calendar/entries#destroy"
    patch  "calendar/entries/:id/toggle_watched",   to: "calendar/entries#toggle_watched"

    namespace :favourites do
      resources :items, only: [ :show ], param: :tmdb_movie_id
      post "items/:tmdb_movie_id/toggle", to: "items#toggle", as: :toggle_item
    end
  end
end
