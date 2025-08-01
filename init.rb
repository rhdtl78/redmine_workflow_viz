require 'redmine'

# 플러그인 파일들 로드
plugin_root = File.dirname(__FILE__)
require File.join(plugin_root, 'lib', 'workflow_viz_hooks')

Redmine::Plugin.register :redmine_workflow_viz do
  name 'Redmine Workflow Viz plugin'
  author 'R.SUETSUGU'
  description 'Visualization of workflow definition'
  version '1.0.4'
  url 'http://github.com/suer/redmine_workflow_viz'
  author_url 'http://d.hatena.ne.jp/suer'
  
  requires_redmine :version_or_higher => '6.0.0'
  
  # 플러그인 설정
  settings :default => {
    'chart_width' => '500',
    'chart_height' => '500'
  }, :partial => 'settings/workflow_viz_settings'
end
