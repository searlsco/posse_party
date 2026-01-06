Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check
  get "status" => "status#show"

  mount Searls::Auth::Engine => "/auth"
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :accounts do
    member do
      get :renew_credentials
    end
    collection do
      get :credential_fields
      get :override_fields
      patch :set_syndication
    end
  end
  resources :feeds do
    member do
      patch :check
    end
  end
  resources :posts, only: [:index, :show, :destroy] do
    post :create_crosspost, on: :member
  end
  resources :crossposts, only: [:show, :destroy] do
    member do
      patch :publish
      patch :skip
    end
  end
  resources :logs, only: [:index, :show, :destroy] do
    collection do
      delete :destroy_all
      post :mark_all_seen
    end
  end
  resource :settings do
    patch :regenerate_api_key
    get :api
  end
  resource :account_deletion, only: [:destroy]
  resources :invites, only: [:new, :create, :destroy] do
    post :remind, on: :member
  end
  resources :users, only: [:update, :destroy]

  namespace :api do
    get "crossposts", to: "crossposts#index"
  end

  # Credential renewal callbacks
  get "credential_renewals/linkedin" => "credential_renewals#linkedin"
  get "credential_renewals/youtube" => "credential_renewals#youtube"

  resource :policies, only: [] do
    get :privacy
  end

  resources :docs, only: [:index, :show]

  # Test-only routes
  if Rails.env.local?
    get "/test/session", to: "test#set_session_var"
    get "/test/feed_fixture/:fixture", to: "test#feed_fixture", as: :test_feed_fixture, format: false
    get "/test/latest_email", to: "test#latest_email"
  end

  root to: "posts#index"
end
