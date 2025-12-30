Rails.application.routes.draw do
  root "dashbroad#index"

  resources :bots, only: [:index, :new, :create, :show] do
    member do
      post :add_prompt
      post :import_excel   # 👈 THÊM DÒNG NÀY
      post :train
      get  :run
      post :stop
    end

    resources :prompts, only: [:destroy]
  end

  get '/bots/:id/live-chat', to: 'bots#chat', as: 'bot_chat_ui'
  post '/bots/:id/chat',      to: 'bots#chat_response', as: 'bot_chat'

  namespace :api do
    resources :categories
    resources :chatsessions, only: [:create]
    resources :products do
      collection do
        get :hot
        get :by_category
        get :search
        get :by_price_range
      end
    end
  end

  mount ActionCable.server => '/cable'
  get  '/embed_chat', to: 'chat#embed_chat'
  post '/chat_api/message', to: 'chat_api#message'

  namespace :admin do
    resources :chatsessions, only: [:index, :show]
  end
end
