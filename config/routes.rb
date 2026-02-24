Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root "dashboard#show"
  get "dashboard", to: "dashboard#show"

  resources :invitations, only: %i[index new create destroy]
  resources :invitation_acceptances, only: %i[show update], param: :token

  resource :settings, only: %i[edit update]

  resource :google_calendar, only: [], controller: "google_calendar" do
    get :connect
    get :callback
    delete :disconnect
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
