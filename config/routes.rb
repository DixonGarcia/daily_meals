Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "meal_plans#index"

  resource :session, only: [:new, :create, :destroy]

  resources :dishes
  resources :ingredients

  resources :meal_plans, only: [:index] do
    collection do
      patch :update_day
    end
  end

  resources :ai_chat_sessions, only: [:create, :destroy] do
    member do
      patch :switch
      post :apply
    end
    resources :ai_chat_messages, only: [:create]
  end

  resource :ai_copilot, only: [], controller: 'ai_copilots' do
    get :export
    post :import
  end

  resources :api_keys, only: [:index, :create, :destroy, :update]

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :dishes, only: [:index] do
        collection do
          post :import
        end
      end
      resources :meal_plans, only: [:index] do
        collection do
          post :import
        end
      end
    end
  end
end
