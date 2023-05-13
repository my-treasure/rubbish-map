Rails.application.routes.draw do
  root to: "posts#index"
  devise_for :users
  resources :posts do
    member do
      post :like
      delete :unlike
    end

    resources :comments, only: [:create, :destroy]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
