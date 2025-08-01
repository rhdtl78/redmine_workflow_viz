# 프로젝트별 워크플로우 시각화 라우트
resources :projects do
  resources :workflow_viz, only: [:index, :show] do
    member do
      get :export
      post :update_settings
    end
    collection do
      get :tracker_workflow
      get :status_transitions
    end
  end
end

# 관리자 워크플로우 시각화 라우트
resources :workflow_viz_admin, only: [:index, :show] do
  collection do
    get :global_workflow
    get :tracker_overview
    post :bulk_export
  end
end

# API 라우트
namespace :api do
  namespace :v1 do
    resources :workflow_viz, only: [:index, :show] do
      collection do
        get :mermaid_data
        get :workflow_json
      end
    end
  end
end
