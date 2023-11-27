Rails.application.routes.draw do
  root 'health#check'

  resources :users, only: [], param: :email do
    resources :requests, only: [:index, :show, :create]
  end

  resources :projects, only: [:index, :show] do
    member do
      get :enable
    end
  end
end
