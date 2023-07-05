Rails.application.routes.draw do
  resources :users, only: [], param: :email do
    resources :requests, only: [:index, :show, :create]
  end
end
