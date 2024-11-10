Rails.application.routes.draw do
  root 'health#check'
  get 'health/check/:slug' => 'health#show'

  resources :users, only: [], param: :email do
    resources :requests, only: [:index, :show, :create]
  end

  resources :projects, only: [], param: :slug do
    member do
      post :enable
    end
  end
end
