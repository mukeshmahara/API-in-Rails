Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'api/index'
    end
  end
end
