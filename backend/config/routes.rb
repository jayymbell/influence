Rails.application.routes.draw do
  devise_for :users,  path: '',path_names: {
      sign_in: 'login',
      sign_out: 'logout',
      registration: 'signup'
    },
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations",
      confirmations: "users/confirmations",
      passwords: "users/passwords"
  }

  namespace :users do
    resources :events, only: [:create, :index]
    post 'refresh-token', to: 'refresh_tokens#create'
  end

  resources :roles
  resources :users, only: [:index, :show, :destroy, :update]
  resources :people, only: [:index, :show, :create, :update, :destroy] do
    member do
      post   :invite
      delete :invitation, action: :revoke_invitation
    end
  end

  post 'invitations/accept', to: 'invitations#accept'

  resources :conversations, only: [:index, :show, :create, :update, :destroy] do
    post :messages, to: "conversations#send_message", on: :member
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
