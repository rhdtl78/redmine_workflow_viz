require 'redmine'

Rails.logger.info "=== WORKFLOW VIZ PLUGIN LOADING ==="

# 플러그인 파일들 로드
plugin_root = File.dirname(__FILE__)

begin
  require File.join(plugin_root, 'lib', 'workflow_viz_hooks')
  Rails.logger.info "✓ workflow_viz_hooks.rb loaded successfully"
rescue => e
  Rails.logger.error "✗ Failed to load workflow_viz_hooks.rb: #{e.message}"
end

begin
  require File.join(plugin_root, 'lib', 'workflows_controller_patch')
  Rails.logger.info "✓ workflows_controller_patch.rb loaded successfully"
rescue => e
  Rails.logger.error "✗ Failed to load workflows_controller_patch.rb: #{e.message}"
end

Redmine::Plugin.register :redmine_workflow_viz do
  name 'Redmine Workflow Viz plugin'
  author 'R.SUETSUGU'
  description 'Modern workflow visualization using Mermaid.js diagrams'
  version '2.0.2'
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

Rails.logger.info "=== WORKFLOW VIZ PLUGIN REGISTERED ==="
