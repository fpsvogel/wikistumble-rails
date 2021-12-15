Rails.application.routes.draw do
  root 'recommendations#show', as: :recommendations_show

  patch 'recommendations/update'
end
