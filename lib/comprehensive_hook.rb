class ComprehensiveHook < Redmine::Hook::ViewListener
  
  # 가장 일반적인 훅들
  def view_layouts_base_body_bottom(context = {})
    log_and_return("view_layouts_base_body_bottom", "🔴 BASE BODY BOTTOM")
  end
  
  def view_layouts_base_body_top(context = {})
    log_and_return("view_layouts_base_body_top", "🟠 BASE BODY TOP")
  end
  
  def view_layouts_base_content(context = {})
    log_and_return("view_layouts_base_content", "🟡 BASE CONTENT")
  end
  
  def view_layouts_base_sidebar(context = {})
    log_and_return("view_layouts_base_sidebar", "🟢 BASE SIDEBAR")
  end
  
  # 워크플로우 관련 훅들
  def view_workflows_edit_bottom(context = {})
    controller = context[:controller]
    if controller && controller.class.name == 'WorkflowsController'
      log_and_return("view_workflows_edit_bottom", "🔵 WORKFLOWS EDIT BOTTOM")
    else
      ""
    end
  end
  
  def view_workflows_edit_top(context = {})
    controller = context[:controller]
    if controller && controller.class.name == 'WorkflowsController'
      log_and_return("view_workflows_edit_top", "🟣 WORKFLOWS EDIT TOP")
    else
      ""
    end
  end
  
  # HTML head 훅
  def view_layouts_base_html_head(context = {})
    Rails.logger.info "=== ComprehensiveHook#view_layouts_base_html_head called ==="
    puts "=== ComprehensiveHook#view_layouts_base_html_head called ==="
    
    <<-HTML.html_safe
    <script>
      console.log('ComprehensiveHook: HTML head hook working');
      document.addEventListener('DOMContentLoaded', function() {
        console.log('ComprehensiveHook: DOM loaded, looking for hooks...');
        
        // 훅이 작동했는지 확인
        setTimeout(function() {
          var hooks = document.querySelectorAll('[data-hook]');
          console.log('Found ' + hooks.length + ' hook elements');
          hooks.forEach(function(hook) {
            console.log('Hook found:', hook.getAttribute('data-hook'));
          });
        }, 1000);
      });
    </script>
    HTML
  end
  
  private
  
  def log_and_return(hook_name, display_text)
    Rails.logger.info "=== ComprehensiveHook##{hook_name} called ==="
    puts "=== ComprehensiveHook##{hook_name} called ==="
    
    <<-HTML.html_safe
    <div data-hook="#{hook_name}" style="position: fixed; top: #{rand(100) + 10}px; right: 10px; background: #333; color: white; padding: 5px 10px; z-index: 9999; border-radius: 3px; font-size: 12px; margin-bottom: 5px;">
      #{display_text}
    </div>
    HTML
  end
end

Rails.logger.info "=== ComprehensiveHook class loaded ==="
puts "=== ComprehensiveHook class loaded ==="
