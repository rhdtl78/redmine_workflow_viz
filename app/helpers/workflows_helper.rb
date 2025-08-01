module WorkflowsHelper
  def generate_graph(role, tracker)
    return "" unless role && tracker
    
    edges = role.workflows.select { |workflow| workflow.tracker_id == tracker.id }
                         .map { |workflow| "#{sanitize_status_name(workflow.old_status)}->#{sanitize_status_name(workflow.new_status)}" }
                         .join(";")
    
    return "" if edges.blank?
    
    # 설정에서 차트 크기 가져오기
    width = Setting.plugin_redmine_workflow_viz['chart_width'] || '500'
    height = Setting.plugin_redmine_workflow_viz['chart_height'] || '500'
    
    # Google Chart API 사용 (HTTPS로 변경)
    chart_url = "https://chart.googleapis.com/chart"
    params = {
      cht: 'gv',
      chl: "digraph{#{CGI.escape(edges)}}",
      chs: "#{width}x#{height}"
    }
    
    "#{chart_url}?#{params.to_query}"
  end
  
  private
  
  def sanitize_status_name(status)
    return "" unless status
    status.name.gsub(/[^a-zA-Z0-9_]/, '_')
  end
end

