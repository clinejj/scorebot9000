Rails.application.routes.draw do
  # Health check for Fly and uptime monitors (excluded from force_ssl).
  get "up" => "rails/health#show", as: :rails_health_check

  get "privacy" => "pages#privacy"
  get "sms-terms" => "pages#sms_terms", as: :sms_terms

  root "pages#home"
end
