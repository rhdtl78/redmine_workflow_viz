class WorkflowVisualizationHook < Redmine::Hook::ViewListener
  
  def view_workflows_edit_bottom(context = {})
    Rails.logger.info "=== WorkflowVisualizationHook#view_workflows_edit_bottom called ==="
    puts "=== WorkflowVisualizationHook#view_workflows_edit_bottom called ==="
    
    controller = context[:controller]
    request = context[:request]
    
    return '' unless controller && request
    return '' unless controller.class.name == 'WorkflowsController'
    
    # 파라미터에서 role과 tracker 가져오기
    params = request.params || {}
    role_id = params[:role_id]
    tracker_id = params[:tracker_id]
    
    Rails.logger.info "Workflow params - role_id: #{role_id.inspect}, tracker_id: #{tracker_id.inspect}"
    puts "Workflow params - role_id: #{role_id.inspect}, tracker_id: #{tracker_id.inspect}"
    
    # 배열인 경우 첫 번째 값 사용
    role_id = role_id.first if role_id.is_a?(Array)
    tracker_id = tracker_id.first if tracker_id.is_a?(Array)
    
    # 파라미터가 없어도 기본 시각화 표시
    if role_id.blank? || tracker_id.blank?
      return generate_parameter_selection_html(params)
    end
    
    begin
      role = Role.find_by(id: role_id)
      tracker = Tracker.find_by(id: tracker_id)
      
      Rails.logger.info "Found role: #{role&.name}, tracker: #{tracker&.name}"
      puts "Found role: #{role&.name}, tracker: #{tracker&.name}"
      
      return '' unless role && tracker
      
      # 워크플로우 데이터 가져오기
      workflows = WorkflowTransition.where(role_id: role.id, tracker_id: tracker.id)
      Rails.logger.info "Found #{workflows.count} workflow transitions"
      puts "Found #{workflows.count} workflow transitions"
      
      if workflows.any?
        generate_mermaid_visualization(role, tracker, workflows)
      else
        generate_no_workflow_html(role, tracker)
      end
      
    rescue => e
      Rails.logger.error "Workflow visualization error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      puts "Workflow visualization error: #{e.message}"
      
      generate_error_html(e.message)
    end
  end
  
  def view_layouts_base_html_head(context = {})
    controller = context[:controller]
    if controller && controller.class.name == 'WorkflowsController'
      <<-HTML.html_safe
      <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
      <script>
        console.log('WorkflowViz: Mermaid.js loaded');
        document.addEventListener('DOMContentLoaded', function() {
          if (typeof mermaid !== 'undefined') {
            mermaid.initialize({ 
              startOnLoad: true,
              theme: 'default',
              flowchart: {
                useMaxWidth: true,
                htmlLabels: true,
                curve: 'basis'
              }
            });
            console.log('WorkflowViz: Mermaid initialized');
          } else {
            console.error('WorkflowViz: Mermaid not loaded');
          }
        });
      </script>
      HTML
    else
      ''
    end
  end
  
  private
  
  def generate_parameter_selection_html(params)
    <<-HTML.html_safe
    <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 2px solid #17a2b8; border-radius: 4px; background-color: #e6f7ff;">
      <h3>🔍 Workflow Visualization</h3>
      <p>Select a role and tracker above, then click "Edit" to see the workflow visualization.</p>
      <p><small>Available parameters: #{params.keys.join(', ')}</small></p>
    </div>
    HTML
  end
  
  def generate_no_workflow_html(role, tracker)
    <<-HTML.html_safe
    <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 2px solid #ffc107; border-radius: 4px; background-color: #fff3cd;">
      <h3>⚠️ Workflow Visualization</h3>
      <p>No workflow transitions are defined for:</p>
      <ul>
        <li><strong>Role:</strong> #{ERB::Util.html_escape(role.name)}</li>
        <li><strong>Tracker:</strong> #{ERB::Util.html_escape(tracker.name)}</li>
      </ul>
      <p>Configure workflow transitions above to see the visualization.</p>
    </div>
    HTML
  end
  
  def generate_error_html(error_message)
    <<-HTML.html_safe
    <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 2px solid #dc3545; border-radius: 4px; background-color: #ffe6e6;">
      <h3>❌ Workflow Visualization Error</h3>
      <p>An error occurred while generating the workflow visualization:</p>
      <p><code>#{ERB::Util.html_escape(error_message)}</code></p>
    </div>
    HTML
  end
  
  def generate_mermaid_visualization(role, tracker, workflows)
    # Mermaid 그래프 정의 생성
    mermaid_definition = build_mermaid_graph(workflows)
    graph_id = "workflow-graph-#{role.id}-#{tracker.id}"
    
    <<-HTML.html_safe
    <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 2px solid #28a745; border-radius: 4px; background-color: #e6ffe6;">
      <h3>📊 Workflow Visualization</h3>
      <p><strong>Role:</strong> #{ERB::Util.html_escape(role.name)} | <strong>Tracker:</strong> #{ERB::Util.html_escape(tracker.name)}</p>
      
      <div id="#{graph_id}" style="text-align: center; padding: 20px; background: white; border: 1px solid #ddd; border-radius: 4px; margin: 10px 0;">
        <div class="mermaid">
#{mermaid_definition}
        </div>
      </div>
      
      <p style="font-size: 12px; color: #666; text-align: center;">
        Showing #{workflows.count} workflow transition(s)
      </p>
      
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          if (typeof mermaid !== 'undefined') {
            console.log('WorkflowViz: Rendering graph for #{graph_id}');
            mermaid.init(undefined, document.getElementById('#{graph_id}'));
          }
        });
      </script>
    </div>
    HTML
  end
  
  def build_mermaid_graph(workflows)
    # 상태들과 전환 관계 수집
    statuses = Set.new
    transitions = []
    
    workflows.each do |workflow|
      old_status = workflow.old_status
      new_status = workflow.new_status
      
      next unless old_status && new_status
      
      old_name = sanitize_name(old_status.name)
      new_name = sanitize_name(new_status.name)
      
      statuses.add({ id: old_name, name: old_status.name })
      statuses.add({ id: new_name, name: new_status.name })
      transitions << "#{old_name} --> #{new_name}"
    end
    
    return "graph TD\n    A[No transitions defined]" if transitions.empty?
    
    # Mermaid 그래프 정의 생성
    definition = ["graph TD"]
    
    # 상태 노드 정의
    statuses.each do |status|
      definition << "    #{status[:id]}[\"#{status[:name]}\"]"
    end
    
    # 전환 관계 추가
    transitions.each do |transition|
      definition << "    #{transition}"
    end
    
    definition.join("\n")
  end
  
  def sanitize_name(name)
    return "unknown" unless name
    # Mermaid에서 사용할 수 있는 안전한 이름으로 변환
    name.to_s.gsub(/[^a-zA-Z0-9]/, '_').gsub(/^_+|_+$/, '').gsub(/_+/, '_')
  end
end

Rails.logger.info "=== WorkflowVisualizationHook class loaded ==="
puts "=== WorkflowVisualizationHook class loaded ==="
