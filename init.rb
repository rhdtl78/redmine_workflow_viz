require 'redmine'

Redmine::Plugin.register :redmine_workflow_viz do
  name 'Redmine Workflow Viz plugin'
  author 'R.SUETSUGU'
  description 'Visualization of workflow definition'
  version '1.0.2'
  url 'http://github.com/suer/redmine_workflow_viz'
  author_url 'http://d.hatena.ne.jp/suer'
  
  requires_redmine :version_or_higher => '6.0.0'
  
  # 플러그인 설정
  settings :default => {
    'chart_width' => '500',
    'chart_height' => '500'
  }, :partial => 'settings/workflow_viz_settings'
end

# 컨트롤러 패치 및 뷰 훅 로드
Rails.application.config.to_prepare do
  require_dependency File.expand_path('../lib/workflows_controller_patch', __FILE__)
  require_dependency File.expand_path('../lib/hooks/workflow_viz_hooks', __FILE__)
end
