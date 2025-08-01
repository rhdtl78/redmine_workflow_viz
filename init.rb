require 'redmine'

# 플러그인 파일들 로드
plugin_root = File.dirname(__FILE__)
require File.join(plugin_root, 'lib', 'workflow_viz_hooks')
require File.join(plugin_root, 'lib', 'workflows_controller_patch')

Redmine::Plugin.register :redmine_workflow_viz do
  name 'Redmine Workflow Viz plugin'
  author 'R.SUETSUGU'
  description 'Modern workflow visualization using Mermaid.js diagrams'
  version '2.0.1'
  url 'http://github.com/suer/redmine_workflow_viz'
  author_url 'http://d.hatena.ne.jp/suer'
  
  requires_redmine :version_or_higher => '6.0.0'
  
  # 플러그인 설정
  settings :default => {
    'theme' => 'default',
    'show_labels' => '1',
    'enable_animation' => '1'
  }, :partial => 'settings/workflow_viz_settings'
end
