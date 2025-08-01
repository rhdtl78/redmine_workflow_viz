module WorkflowsHelper
  def generate_graph(role, tracker)
    return "" unless role && tracker
    
    begin
      # 워크플로우 데이터 가져오기
      workflows = role.workflows.where(tracker_id: tracker.id)
      return "" if workflows.empty?
      
      edges = workflows.map do |workflow|
        old_status_name = sanitize_status_name(workflow.old_status)
        new_status_name = sanitize_status_name(workflow.new_status)
        "#{old_status_name}->#{new_status_name}"
      end.join(";")
      
      return "" if edges.blank?
      
      # 설정에서 차트 크기 가져오기
      settings = Setting.plugin_redmine_workflow_viz || {}
      width = settings['chart_width'] || '500'
      height = settings['chart_height'] || '500'
      
      # Google Chart API 사용 (HTTPS로 변경)
      chart_url = "https://chart.googleapis.com/chart"
      params = {
        cht: 'gv',
        chl: "digraph{#{CGI.escape(edges)}}",
        chs: "#{width}x#{height}"
      }
      
      "#{chart_url}?#{params.to_query}"
    rescue => e
      Rails.logger.error "Workflow visualization error: #{e.message}"
      ""
    end
  end
  
  private
  
  def sanitize_status_name(status)
    return "unknown" unless status && status.respond_to?(:name)
    status.name.to_s.gsub(/[^a-zA-Z0-9_]/, '_')
  end
end

