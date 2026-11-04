Rails.application.routes.draw do
  devise_for :users

  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"

      resources :employees, only: %i[index show create update] do
        resources :salary_histories, only: %i[index show create update] do
          member do
            post :cancel
          end
        end
      end

      resources :countries, only: [:index]
      resources :departments, only: [:index]
      resources :job_titles, only: [:index]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
