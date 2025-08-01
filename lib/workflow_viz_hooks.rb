class WorkflowVizHooks < Redmine::Hook::ViewListener
  
  # 여러 훅 포인트 시도
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
  
  def view_layouts_base_html_head(context = {})
    # Mermaid.js 라이브러리를 head에 추가
    <<-HTML.html_safe
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
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
        }
      });
    </script>
    HTML
  end
  
  private
  
  def generate_visualization_html(context, hook_name)
    Rails.logger.info "Context keys: #{context.keys}"
    
    return '' unless context.is_a?(Hash)
    
    # 안전하게 컨텍스트에서 필요한 변수들 추출
    controller = context[:controller]
    request = context[:request]
    
    Rails.logger.info "Controller: #{controller.class.name}" if controller
    Rails.logger.info "Request present: #{request.present?}"
    
    return '' unless controller && request
    
    # 워크플로우 컨트롤러인지 확인
    return '' unless controller.class.name == 'WorkflowsController'
    
    # 현재 선택된 role과 tracker 가져오기
    params = request.params || {}
    role_id = params[:role_id]
    tracker_id = params[:tracker_id]
    
    Rails.logger.info "Raw params - role_id: #{role_id.inspect}, tracker_id: #{tracker_id.inspect}"
    
    # role_id가 배열인 경우 첫 번째 값 사용
    role_id = role_id.first if role_id.is_a?(Array)
    tracker_id = tracker_id.first if tracker_id.is_a?(Array)
    
    Rails.logger.info "Processed params - role_id: #{role_id}, tracker_id: #{tracker_id}"
    
    # 파라미터가 없어도 일단 테스트용 HTML 반환 (훅이 작동하는지 확인)
    if role_id.blank? || tracker_id.blank?
      Rails.logger.info "Missing parameters, returning test HTML"
      return <<-HTML.html_safe
      <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 2px solid #007cba; border-radius: 4px; background-color: #e6f3ff;">
        <h3>🔧 Workflow Visualization (Debug - #{hook_name})</h3>
        <p><strong>Hook is working!</strong></p>
        <p>Parameters: role_id=#{role_id.inspect}, tracker_id=#{tracker_id.inspect}</p>
        <p>Available params: #{params.keys.join(', ')}</p>
        <p>Controller: #{controller.class.name}</p>
        <p>Action: #{controller.action_name}</p>
      </div>
      HTML
    end
    
    begin
      role = Role.find_by(id: role_id)
      tracker = Tracker.find_by(id: tracker_id)
      
      Rails.logger.info "Found role: #{role&.name}, tracker: #{tracker&.name}"
      
      return '' unless role && tracker
      
      # 플러그인 전용 헬퍼 사용
      helper = Object.new
      helper.extend(WorkflowVizHelper)
      
      # Mermaid.js 그래프 생성
      visualization_html = helper.generate_workflow_mermaid_graph(role, tracker)
      
      Rails.logger.info "Generated visualization HTML length: #{visualization_html.length}"
      
      return visualization_html if visualization_html.present?
      
      # 워크플로우가 없는 경우 메시지 표시
      <<-HTML.html_safe
      <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 4px; background-color: #f9f9f9;">
        <h3>Workflow Visualization (#{hook_name})</h3>
        <p class="info">No workflow transitions defined for role "#{ERB::Util.html_escape(role.name)}" and tracker "#{ERB::Util.html_escape(tracker.name)}".</p>
      </div>
      HTML
    rescue => e
      Rails.logger.error "Workflow visualization hook error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
      
      # 에러 상황에서도 디버그 정보 표시
      <<-HTML.html_safe
      <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 2px solid #dc3545; border-radius: 4px; background-color: #ffe6e6;">
        <h3>Workflow Visualization (Error - #{hook_name})</h3>
        <p>Error occurred: #{ERB::Util.html_escape(e.message)}</p>
      </div>
      HTML
    end
  end
end
