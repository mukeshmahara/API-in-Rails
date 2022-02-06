Rails.application.routes.draw do
  namespace :Api do
    namespace :V1 do
      get 'api/index',
      # resources: logi
    end
  end
end
