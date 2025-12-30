Rails.application.routes.draw do
  resources :patients, only: [ :index, :show ]

  namespace :api do
    namespace :v1 do
      namespace :fhir do
        resources :observations, only: [ :create, :index ], defaults: { format: :json }
        resources :bundles, only: :create, defaults: { format: :json }
      end
    end
  end

  resource :account, only: [ :edit, :update ] do
    post :switch
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "patients#index"
end
