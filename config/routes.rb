Rails.application.routes.draw do
  # Health check for Fly and uptime monitors (excluded from force_ssl).
  get "up" => "rails/health#show", as: :rails_health_check

  # Passwordless sign-in.
  resource :session, only: %i[new create destroy] do
    get :verify
    post :verify, action: :confirm
  end
  get "sign_in" => "sessions#new"

  # Platform admin tools. Every route here requires a signed-in platform admin;
  # for anyone else they don't exist (404). See AdminConstraint.
  constraints(AdminConstraint) do
    mount Flipper::UI.app(Flipper) => "/admin/flipper"
    mount Blazer::Engine => "/admin/blazer"
    mount MaintenanceTasks::Engine => "/admin/maintenance_tasks"
    mount MissionControl::Jobs::Engine => "/admin/jobs"

    namespace :admin do
      root "dashboard#show"
      resources :legacy_imports, only: %i[index new create show] do
        post :run, on: :member
      end
    end
  end

  get "privacy" => "pages#privacy"
  get "sms-terms" => "pages#sms_terms", as: :sms_terms

  root "pages#home"
end
