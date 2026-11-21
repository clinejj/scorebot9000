Rails.application.routes.draw do
  # Health check for Fly and uptime monitors (excluded from force_ssl).
  get "up" => "rails/health#show", as: :rails_health_check

  # Passwordless sign-in.
  resource :session, only: %i[new create destroy] do
    get :verify
    post :verify, action: :confirm
  end
  get "sign_in" => "sessions#new"

  # Your account: profile, linked email/phone, your events.
  resource :account, only: %i[show update], path: "me"
  resources :identifiers, only: %i[new create], path: "me/identifiers" do
    collection do
      get :verify
      post :verify, action: :confirm
    end
  end

  # Platform admin tools. Every route here requires a signed-in platform admin;
  # for anyone else they don't exist (404). See AdminConstraint.
  constraints(AdminConstraint) do
    mount Flipper::UI.app(Flipper) => "/admin/flipper"
    mount Blazer::Engine => "/admin/blazer"
    mount MaintenanceTasks::Engine => "/admin/maintenance_tasks"
    mount MissionControl::Jobs::Engine => "/admin/jobs"

    namespace :admin do
      root "dashboard#show"
      resources :sms_messages, only: %i[index create], path: "sms"
      resources :legacy_imports, only: %i[index new create show] do
        post :run, on: :member
      end
    end
  end

  # Organizer console.
  namespace :manage do
    root "dashboard#show"
    match "scoring_preview", to: "scoring_previews#create", via: %i[post patch], as: :scoring_preview
    resources :series, only: %i[new create edit update], param: :slug
    resources :events, only: %i[new create show edit update destroy], param: :slug do
      resource :lifecycle, only: :update
      resources :games, only: %i[index create edit update destroy], param: :position do
        patch :move, on: :member
      end
      resources :teams, only: %i[index create update destroy] do
        post :randomize, on: :collection
      end
      resources :participants, only: %i[index create update destroy], path: "players"
      resources :score_sheets, only: %i[index show update], param: :position, path: "scores"
      resources :score_entries, only: :destroy
      resources :adjustments, only: %i[index create destroy]
      resources :sms, only: %i[index create], controller: "sms"
      resources :memberships, only: %i[index create destroy], path: "organizers"
    end
  end

  # Public pages. A series' custom domain (clinelympics.com) roots at its
  # series page; everything else works on any host.
  constraints(CustomDomainConstraint) do
    get "/", to: "series#show", as: :series_domain_root
  end
  get "s/:slug", to: "series#show", as: :series
  resources :events, path: "e", param: :slug, only: :show do
    member do
      get :results
      get :tv
    end
    resources :games, only: :show, param: :position
    resources :teams, only: :show
    resource :registration, only: %i[new create update], path: "join"
    resources :submissions, only: :create do
      delete :undo, on: :collection
    end
  end

  # Twilio inbound SMS webhook (/inbound is the legacy URL, kept during cutover).
  post "twilio/sms" => "sms_webhooks#create", as: :twilio_sms
  post "inbound" => "sms_webhooks#create"

  # Old clinelympics.com URLs.
  %w[summary medals scores details index admin].each do |page|
    get "#{page}.jsp", to: "legacy_redirects#show", defaults: { page: page }
  end

  get "privacy" => "pages#privacy"
  get "sms-terms" => "pages#sms_terms", as: :sms_terms

  root "pages#home"
end
