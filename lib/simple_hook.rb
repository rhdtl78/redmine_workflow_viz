class SimpleHook < Redmine::Hook::ViewListener
  def view_layouts_base_body_bottom(context = {})
    Rails.logger.info "=== SimpleHook#view_layouts_base_body_bottom called ==="
    puts "=== SimpleHook#view_layouts_base_body_bottom called ==="
    
    <<-HTML.html_safe
    <div style="position: fixed; bottom: 10px; right: 10px; background: #ff0000; color: white; padding: 10px; z-index: 9999; border-radius: 5px;">
      🔴 HOOK WORKING!
    </div>
    HTML
  end
  
  def view_layouts_base_html_head(context = {})
    Rails.logger.info "=== SimpleHook#view_layouts_base_html_head called ==="
    puts "=== SimpleHook#view_layouts_base_html_head called ==="
    
    <<-HTML.html_safe
    <script>
      console.log('SimpleHook: HTML head hook working');
      document.addEventListener('DOMContentLoaded', function() {
        console.log('SimpleHook: DOM loaded');
      });
    </script>
    HTML
  end
  
  def view_workflows_edit_bottom(context = {})
    Rails.logger.info "=== SimpleHook#view_workflows_edit_bottom called ==="
    puts "=== SimpleHook#view_workflows_edit_bottom called ==="
    
    controller = context[:controller]
    if controller && controller.class.name == 'WorkflowsController'
      <<-HTML.html_safe
      <div style="margin-top: 20px; padding: 15px; border: 3px solid #00ff00; border-radius: 4px; background-color: #e6ffe6;">
        <h3>🟢 WORKFLOW HOOK WORKING!</h3>
        <p>This is displayed by view_workflows_edit_bottom hook</p>
        <p>Controller: #{controller.class.name}</p>
        <p>Action: #{controller.action_name}</p>
        <p>Time: #{Time.current}</p>
      </div>
      HTML
    else
      ''
    end
  end
end

Rails.logger.info "=== SimpleHook class loaded ==="
puts "=== SimpleHook class loaded ==="
