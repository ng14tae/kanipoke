Rails.application.routes.draw do
  get "users/index"
  get "login", to: "user_sessions#new"
  post "login", to: "user_sessions#create"
  delete "logout", to: "user_sessions#destroy"
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  root "home#index"

  # 一般ユーザー画面
  resources :battles, only: [ :new, :create, :show, :index ]
  resources :users, only: [ :index, :create, :show, :new, :edit, :update ]


  # 管理画面（名前空間分離）
  namespace :admin do
    root "dashboard#index"
    resources :users, only: [ :index, :show ]
    resources :battles, only: [ :index, :show ]
  end
end
