Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root "dashboard#show"
  get "dashboard", to: "dashboard#show"
  get "privacy", to: "legal#privacy", as: :privacy

  resources :invitations, only: %i[index new create destroy]
  resources :invitation_acceptances, only: %i[show update], param: :token

  resource :settings, only: %i[edit update]
  resource :calendar, only: [ :show ], controller: "calendar"
  resources :team_members, only: %i[destroy]
  resources :workflows do
    member do
      patch :toggle
    end
    resources :workflow_steps, only: [ :create, :show, :edit, :update, :destroy ]
  end

  resources :schedule_links do
    resources :availability_windows, only: [ :index, :create, :destroy ] do
      collection do
        get :copy
        post :copy, action: :perform_copy
      end
    end
  end

  resources :contacts, only: %i[index show update] do
    get :export, on: :collection
  end

  namespace :admin do
    resources :bookings, only: %i[index show] do
      member do
        patch :cancel
      end
    end
  end

  resource :google_calendar_connections, only: [], controller: "google_calendar_connections" do
    get :connect
    get :callback
  end
  resources :google_calendar_connections, only: [ :destroy ]

  resource :google_calendar, only: [], controller: "google_calendar" do
    get :connect
    get :callback
    delete :disconnect
  end

  get "book/:slug", to: "booking_pages#show", as: :booking_page
  get "book/:slug/availability", to: "availability#show", as: :booking_availability
  post "book/:slug/bookings", to: "bookings#create", as: :bookings
  get "book/:slug/bookings/:id/confirmation", to: "bookings#confirmation", as: :booking_confirmation

  get "bookings/:id/cancel", to: "booking_cancellations#show", as: :booking_cancellation
  post "bookings/:id/cancel", to: "booking_cancellations#update"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if defined?(LetterOpenerWeb)
end
