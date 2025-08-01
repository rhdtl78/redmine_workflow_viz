require 'redmine'

# 플러그인 로드 확인을 위한 로그
puts "=== WORKFLOW VIZ PLUGIN INIT.RB LOADING ==="
Rails.logger.info "=== WORKFLOW VIZ PLUGIN INIT.RB LOADING ===" if defined?(Rails.logger)

Redmine::Plugin.register :redmine_workflow_viz do
  name 'Redmine Workflow Viz plugin'
  author 'R.SUETSUGU'
  description 'Modern workflow visualization using Mermaid.js diagrams'
  version '2.0.7'
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

puts "=== WORKFLOW VIZ PLUGIN REGISTERED ==="
Rails.logger.info "=== WORKFLOW VIZ PLUGIN REGISTERED ===" if defined?(Rails.logger)

# 훅 파일들 로드
hook_files = ['simple_hook', 'comprehensive_hook']

hook_files.each do |hook_file|
  begin
    require File.join(File.dirname(__FILE__), 'lib', hook_file)
    puts "=== #{hook_file} loaded successfully ==="
    Rails.logger.info "=== #{hook_file} loaded successfully ===" if defined?(Rails.logger)
  rescue => e
    puts "=== Failed to load #{hook_file}: #{e.message} ==="
    Rails.logger.error "=== Failed to load #{hook_file}: #{e.message} ===" if defined?(Rails.logger)
  end
end

# 간단한 훅 등록 확인만
if defined?(Redmine::Hook)
  puts "=== Redmine::Hook is available ==="
  Rails.logger.info "=== Redmine::Hook is available ===" if defined?(Rails.logger)
else
  puts "=== Redmine::Hook is NOT available ==="
  Rails.logger.error "=== Redmine::Hook is NOT available ===" if defined?(Rails.logger)
end

puts "=== WORKFLOW VIZ PLUGIN INIT.RB COMPLETE ==="
Rails.logger.info "=== WORKFLOW VIZ PLUGIN INIT.RB COMPLETE ===" if defined?(Rails.logger)
