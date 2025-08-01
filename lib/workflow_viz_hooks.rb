class WorkflowVizHooks < Redmine::Hook::ViewListener
  
  Rails.logger.info "=== WorkflowVizHooks class loaded ==="
  
  # 워크플로우 페이지에서만 작동하는 훅들
  def view_workflows_edit_bottom(context = {})
    Rails.logger.info "=== view_workflows_edit_bottom Hook Called ==="
    generate_visualization_html(context, "edit_bottom")
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
    
    return '' unless context.is_a?(Hash)
    
    # 안전하게 컨텍스트에서 필요한 변수들 추출
    controller = context[:controller]
    request = context[:request]
    
    return '' unless controller && request
    
    # 워크플로우 컨트롤러인지 확인
    return '' unless controller.class.name == 'WorkflowsController'
    
    # 현재 선택된 role과 tracker 가져오기
    params = request.params || {}
    role_id = params[:role_id]
    tracker_id = params[:tracker_id]
    
    Rails.logger.info "Params - role_id: #{role_id.inspect}, tracker_id: #{tracker_id.inspect}"
    
    # role_id가 배열인 경우 첫 번째 값 사용
    role_id = role_id.first if role_id.is_a?(Array)
    tracker_id = tracker_id.first if tracker_id.is_a?(Array)
    
    # 파라미터가 없으면 빈 문자열 반환
    return '' if role_id.blank? || tracker_id.blank?
    
    begin
      role = Role.find_by(id: role_id)
      tracker = Tracker.find_by(id: tracker_id)
      
      return '' unless role && tracker
      
      # 플러그인 전용 헬퍼 사용
      helper = Object.new
      helper.extend(WorkflowVizHelper)
      
      # Mermaid.js 그래프 생성
      visualization_html = helper.generate_workflow_mermaid_graph(role, tracker)
      
      if visualization_html.present?
        return visualization_html
      else
        # 워크플로우가 없는 경우 메시지 표시
        <<-HTML.html_safe
        <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 4px; background-color: #f9f9f9;">
          <h3>Workflow Visualization</h3>
          <p class="info">No workflow transitions defined for role "#{ERB::Util.html_escape(role.name)}" and tracker "#{ERB::Util.html_escape(tracker.name)}".</p>
        </div>
        HTML
      end
    rescue => e
      Rails.logger.error "Workflow visualization hook error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
      ''
    end
  end
end

Rails.logger.info "=== WorkflowVizHooks class definition complete ==="
