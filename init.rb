require 'redmine'

# 플러그인 로드 확인을 위한 로그
puts "=== WORKFLOW VIZ PLUGIN INIT.RB LOADING ==="
Rails.logger.info "=== WORKFLOW VIZ PLUGIN INIT.RB LOADING ===" if defined?(Rails.logger)

Redmine::Plugin.register :redmine_workflow_viz do
  name 'Redmine Workflow Viz plugin'
  author 'R.SUETSUGU'
  description 'Modern workflow visualization using Mermaid.js diagrams'
  version '2.0.3'
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

# 간단한 훅 테스트
class SimpleTestHook < Redmine::Hook::ViewListener
  def view_layouts_base_body_bottom(context = {})
    puts "=== SIMPLE TEST HOOK CALLED ==="
    Rails.logger.info "=== SIMPLE TEST HOOK CALLED ===" if defined?(Rails.logger)
    
    <<-HTML.html_safe
    <div style="position: fixed; bottom: 10px; right: 10px; background: red; color: white; padding: 10px; z-index: 9999;">
      WORKFLOW VIZ PLUGIN LOADED!
    </div>
    HTML
  end
end

puts "=== WORKFLOW VIZ PLUGIN INIT.RB COMPLETE ==="
Rails.logger.info "=== WORKFLOW VIZ PLUGIN INIT.RB COMPLETE ===" if defined?(Rails.logger)
