Rails.application.routes.draw do
  devise_for :users

  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"
      get "me", to: "me#show"

      resources :employees, only: %i[index show create update] do
        collection do
          get :export
          post :import
        end

        resources :salary_histories, only: %i[index show create update] do
          member do
            post :cancel
          end
        end
      end

      resources :countries, only: [:index]
      resources :departments, only: [:index]
      resources :job_titles, only: [:index]
      resource :dashboard, only: [] do
        get :overview
        get :employee_distribution
        get :salary_analytics
        get :recent_salary_changes
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
