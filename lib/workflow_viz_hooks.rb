class WorkflowVizHooks < Redmine::Hook::ViewListener
  # 워크플로우 편집 페이지 하단에 시각화 추가
  def view_workflows_edit_bottom(context = {})
    return '' unless context.is_a?(Hash)
    
    # 안전하게 컨텍스트에서 필요한 변수들 추출
    controller = context[:controller]
    request = context[:request]
    
    return '' unless controller && request
    
    # 현재 선택된 role과 tracker 가져오기
    params = request.params || {}
    role_id = params[:role_id]
    tracker_id = params[:tracker_id]
    
    # role_id가 배열인 경우 첫 번째 값 사용
    role_id = role_id.first if role_id.is_a?(Array)
    tracker_id = tracker_id.first if tracker_id.is_a?(Array)
    
    return '' unless role_id.present? && tracker_id.present?
    
    begin
      role = Role.find_by(id: role_id)
      tracker = Tracker.find_by(id: tracker_id)
      
      return '' unless role && tracker
      
      # 플러그인 전용 헬퍼 사용
      helper = Object.new
      helper.extend(WorkflowVizHelper)
      
      # Mermaid.js 그래프 생성
      visualization_html = helper.generate_workflow_mermaid_graph(role, tracker)
      
      return visualization_html if visualization_html.present?
      
      # 워크플로우가 없는 경우 메시지 표시
      <<-HTML.html_safe
      <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 4px; background-color: #f9f9f9;">
        <h3>Workflow Visualization</h3>
        <p class="info">No workflow transitions defined for role "#{ERB::Util.html_escape(role.name)}" and tracker "#{ERB::Util.html_escape(tracker.name)}".</p>
      </div>
      HTML
    rescue => e
      Rails.logger.error "Workflow visualization hook error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
      ''
    end
  end
end
