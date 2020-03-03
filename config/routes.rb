Rails.application.routes.draw do
  resources :posts, only: [:index], defaults: { format: :json }
  get :detail, to: 'posts#detail', defaults: { format: :json }
end
