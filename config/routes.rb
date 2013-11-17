TreasureHunter::Application.routes.draw do
  get 'send_texts/:phone_number/:body', to: 'send_texts#index'

  post "hunt_locations", to: 'hunt_locations#create'
  put "hunt_users/:id", to: 'hunt_users#update'

  post "hunt_users", to: "hunt_users#create"
  post "hunt_users/:id/confirm", to: "hunt_users#confirm_participation"

  get "hunt_users/:id/:hunt_id/store_hunter", to: "hunt_users#store_hunter"

  get "user/:username", to: 'users#show'

  get '/decline', to: 'hunts#decline'

  get '/howtoplay/index', to: 'howtoplay#index'

  devise_for :users

  resources :users, except: [:show]
  resources :hunts
  resources :locations
  resources :clues

  root :to => 'hunts#index'

end
