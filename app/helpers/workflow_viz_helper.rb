module WorkflowVizHelper
  def generate_workflow_mermaid_graph(role, tracker)
    return "" unless role && tracker
    
    begin
      # WorkflowTransition 모델을 직접 사용하여 워크플로우 데이터 가져오기
      workflows = WorkflowTransition.where(role_id: role.id, tracker_id: tracker.id)
      return "" if workflows.empty?
      
      # Mermaid.js 그래프 정의 생성
      mermaid_definition = generate_mermaid_definition(workflows)
      
      return "" if mermaid_definition.blank?
      
      # Mermaid.js 그래프를 렌더링할 HTML 반환
      render_mermaid_graph(mermaid_definition, role, tracker)
    rescue => e
      Rails.logger.error "Workflow visualization error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      ""
    end
  end
  
  private
  
  def generate_mermaid_definition(workflows)
    # 상태들과 전환 관계 수집
    statuses = Set.new
    transitions = []
    
    workflows.each do |workflow|
      old_status = workflow.old_status
      new_status = workflow.new_status
      
      next unless old_status && new_status
      
      old_name = sanitize_mermaid_name(old_status.name)
      new_name = sanitize_mermaid_name(new_status.name)
      
      statuses.add(old_name)
      statuses.add(new_name)
      transitions << "#{old_name} --> #{new_name}"
    end
    
    return "" if transitions.empty?
    
    # Mermaid 그래프 정의 생성
    definition = ["graph TD"]
    
    # 상태 노드 정의 (더 나은 표시를 위해)
    statuses.each do |status|
      definition << "  #{status}[\"#{status.gsub('_', ' ')}\"]"
    end
    
    # 전환 관계 추가
    transitions.each do |transition|
      definition << "  #{transition}"
    end
    
    definition.join("\n")
  end
  
  def render_mermaid_graph(mermaid_definition, role, tracker)
    # 고유한 ID 생성
    graph_id = "workflow-graph-#{role.id}-#{tracker.id}"
    
    <<-HTML.html_safe
    <div class="workflow-visualization" style="margin-top: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 4px; background-color: #f9f9f9;">
      <h3>Workflow Visualization</h3>
      <div id="#{graph_id}" style="text-align: center; padding: 10px;">
        <!-- Mermaid 그래프가 여기에 렌더링됩니다 -->
      </div>
      <p style="font-size: 12px; color: #666; text-align: center; margin-top: 10px;">
        Workflow for role: #{ERB::Util.html_escape(role.name)} and tracker: #{ERB::Util.html_escape(tracker.name)}
      </p>
      
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
            
            const graphDefinition = `#{mermaid_definition.gsub('`', '\\`')}`;
            const element = document.getElementById('#{graph_id}');
            
            if (element) {
              mermaid.render('#{graph_id}-svg', graphDefinition).then(function(result) {
                element.innerHTML = result.svg;
              }).catch(function(error) {
                console.error('Mermaid rendering error:', error);
                element.innerHTML = '<p style="color: #999;">Unable to render workflow diagram</p>';
              });
            }
          } else {
            document.getElementById('#{graph_id}').innerHTML = '<p style="color: #999;">Mermaid library not loaded</p>';
          }
        });
      </script>
    </div>
    HTML
  end
  
  def sanitize_mermaid_name(name)
    return "unknown" unless name
    # Mermaid에서 사용할 수 있는 안전한 이름으로 변환
    name.to_s.gsub(/[^a-zA-Z0-9]/, '_').gsub(/^_+|_+$/, '').gsub(/_+/, '_')
  end
end

