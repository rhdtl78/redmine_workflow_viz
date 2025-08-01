Redmine::Plugin.register :redmine_workflow_viz do
  name 'Redmine Workflow Visualization Plugin'
  author 'Kether'
  description 'A plugin to visualize Redmine workflows using Mermaid.js'
  version '1.0.0'
  url 'https://github.com/kether/redmine_workflow_viz'
  author_url 'https://github.com/kether'

  # 프로젝트 메뉴에 워크플로우 시각화 메뉴 추가
  menu :project_menu, :workflow_viz, { 
    controller: 'workflow_viz', 
    action: 'index' 
  }, caption: 'Workflow Visualization', after: :issues

  # 관리자 메뉴에 전역 워크플로우 시각화 메뉴 추가
  menu :admin_menu, :workflow_viz_admin, { 
    controller: 'workflow_viz_admin', 
    action: 'index' 
  }, caption: 'Workflow Visualization'

  # 권한 설정
  project_module :workflow_viz do
    permission :view_workflow_viz, { 
      workflow_viz: [:index, :show, :export] 
    }, public: true
    permission :manage_workflow_viz, { 
      workflow_viz: [:edit, :update] 
    }
  end

  # 설정 페이지 추가
  settings default: {
    'default_diagram_type' => 'flowchart',
    'show_status_colors' => true,
    'enable_export' => true
  }, partial: 'settings/workflow_viz_settings'
end
