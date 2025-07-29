Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "bots#index"

  resources :bots, only: [:index, :new, :create, :show] do
    member do
      post :add_prompt
      post :train
      get :run
      post :stop
    end
    resources :prompts, only: [:destroy]
  end
  # config/routes.rb
  get '/bots/:id/live-chat', to: 'bots#chat', as: 'bot_chat_ui'
  post '/bots/:id/chat',      to: 'bots#chat_response', as: 'bot_chat'
  
  namespace :api do
  resources :categories
  resources :products do
    collection do
      get :hot
      get :by_category
      get :search
      get :by_price_range
    end
  end
  end
  mount ActionCable.server => "/cable"
  get '/embed_chat', to: 'chat#embed_chat'
  post '/chat_api/message', to: 'chat_api#message'
end
