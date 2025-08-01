class WorkflowVizHooks < Redmine::Hook::ViewListener
  
  Rails.logger.info "=== WorkflowVizHooks class loaded ==="
  
  # 모든 페이지 하단에 테스트 메시지 표시 (플러그인이 작동하는지 확인)
  def view_layouts_base_body_bottom(context = {})
    Rails.logger.info "=== view_layouts_base_body_bottom called ==="
    
    controller = context[:controller]
    if controller && controller.class.name == 'WorkflowsController'
      Rails.logger.info "=== WorkflowsController detected ==="
      <<-HTML.html_safe
      <div style="position: fixed; top: 10px; right: 10px; background: #ff6b6b; color: white; padding: 10px; border-radius: 5px; z-index: 9999;">
        🚀 WORKFLOW VIZ PLUGIN IS WORKING!<br>
        Controller: #{controller.class.name}<br>
        Action: #{controller.action_name}
      </div>
      HTML
    else
      ''
    end
  end
  
  # 워크플로우 페이지에서만 작동하는 훅들
  def view_workflows_edit_bottom(context = {})
    Rails.logger.info "=== view_workflows_edit_bottom Hook Called ==="
    generate_visualization_html(context, "edit_bottom")
  end
  
  def view_workflows_edit_top(context = {})
    Rails.logger.info "=== view_workflows_edit_top Hook Called ==="
    generate_visualization_html(context, "edit_top")
  end
  
  def view_workflows_form_bottom(context = {})
    Rails.logger.info "=== view_workflows_form_bottom Hook Called ==="
    generate_visualization_html(context, "form_bottom")
  end
  
  # HTML head에 스크립트 추가
  def view_layouts_base_html_head(context = {})
    controller = context[:controller]
    if controller && controller.class.name == 'WorkflowsController'
      <<-HTML.html_safe
      <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
      <script>
        console.log('Workflow Viz: Mermaid.js loaded');
        document.addEventListener('DOMContentLoaded', function() {
          if (typeof mermaid !== 'undefined') {
            mermaid.initialize({ 
              startOnLoad: true,
              theme: 'default',
              flowchart: {
                useMaxWidth: true,
                htmlLabels: true
              }
            });
            console.log('Workflow Viz: Mermaid initialized');
          }
        });
      </script>
      HTML
    else
      ''
    end
  end
  
  private
  
  def generate_visualization_html(context, hook_name)
    Rails.logger.info "=== generate_visualization_html called for #{hook_name} ==="
    Rails.logger.info "Context keys: #{context.keys}"
    
    return '' unless context.is_a?(Hash)
    
    # 안전하게 컨텍스트에서 필요한 변수들 추출
    controller = context[:controller]
    request = context[:request]
    
    Rails.logger.info "Controller: #{controller&.class&.name}"
    Rails.logger.info "Request present: #{request.present?}"
    
    return '' unless controller && request
    
    # 워크플로우 컨트롤러인지 확인
    return '' unless controller.class.name == 'WorkflowsController'
    
    # 현재 선택된 role과 tracker 가져오기
    params = request.params || {}
    role_id = params[:role_id]
    tracker_id = params[:tracker_id]
    
    Rails.logger.info "Raw params - role_id: #{role_id.inspect}, tracker_id: #{tracker_id.inspect}"
    Rails.logger.info "All params: #{params.inspect}"
    
    # role_id가 배열인 경우 첫 번째 값 사용
    role_id = role_id.first if role_id.is_a?(Array)
    tracker_id = tracker_id.first if tracker_id.is_a?(Array)
    
    Rails.logger.info "Processed params - role_id: #{role_id}, tracker_id: #{tracker_id}"
    
    # 항상 테스트 HTML 반환 (파라미터 유무와 관계없이)
    <<-HTML.html_safe
    <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 3px solid #007cba; border-radius: 4px; background-color: #e6f3ff;">
      <h3>🔧 Workflow Visualization Debug (#{hook_name})</h3>
      <p><strong>Hook #{hook_name} is working!</strong></p>
      <p>Controller: #{controller.class.name}</p>
      <p>Action: #{controller.action_name}</p>
      <p>Role ID: #{role_id.inspect}</p>
      <p>Tracker ID: #{tracker_id.inspect}</p>
      <p>All params: #{params.keys.join(', ')}</p>
      <p>Time: #{Time.current}</p>
    </div>
    HTML
  end
end

Rails.logger.info "=== WorkflowVizHooks class definition complete ==="
