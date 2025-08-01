class WorkflowVizAdminController < ApplicationController
  layout 'admin'
  before_action :require_admin
  
  helper :workflow_viz

  def index
    @trackers = Tracker.all
    @selected_tracker = params[:tracker_id] ? Tracker.find(params[:tracker_id]) : @trackers.first
    
    if @selected_tracker
      @workflow_data = generate_global_workflow_data(@selected_tracker)
      @mermaid_diagram = generate_mermaid_diagram(@workflow_data)
    end
    
    @statistics = calculate_workflow_statistics
  end

  def show
    @tracker = Tracker.find(params[:id])
    @workflow_data = generate_global_workflow_data(@tracker)
    @mermaid_diagram = generate_mermaid_diagram(@workflow_data)
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @workflow_data }
    end
  end

  def global_workflow
    @tracker = Tracker.find(params[:tracker_id])
    @workflow_data = generate_global_workflow_data(@tracker)
    
    render json: {
      mermaid: generate_mermaid_diagram(@workflow_data),
      data: @workflow_data
    }
  end

  def tracker_overview
    @overview_data = Tracker.all.map do |tracker|
      transitions = WorkflowTransition.where(tracker_id: tracker.id)
      {
        tracker: tracker,
        transition_count: transitions.count,
        status_count: transitions.joins(:new_status).distinct.count(:new_status_id),
        role_count: transitions.distinct.count(:role_id)
      }
    end
    
    render json: @overview_data
  end

  def bulk_export
    @export_data = {}
    
    Tracker.all.each do |tracker|
      workflow_data = generate_global_workflow_data(tracker)
      @export_data[tracker.name] = {
        mermaid: generate_mermaid_diagram(workflow_data),
        data: workflow_data
      }
    end
    
    respond_to do |format|
      format.json { render json: @export_data }
      format.zip do
        # ZIP 파일 생성 로직은 별도 구현 필요
        send_data generate_zip_export(@export_data), 
                  filename: "redmine_workflows_#{Date.current}.zip",
                  type: 'application/zip'
      end
    end
  end

  private

  def generate_global_workflow_data(tracker)
    cache_key = "workflow_viz_admin_data_#{tracker.id}_#{tracker.updated_at.to_i}"
    
    if cache_enabled?
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        build_global_workflow_data(tracker)
      end
    else
      build_global_workflow_data(tracker)
    end
  end

  def generate_mermaid_diagram(workflow_data)
    return '' unless workflow_data && workflow_data[:transitions]

    cache_key = "workflow_viz_admin_mermaid_#{workflow_data[:tracker][:id]}_#{Digest::MD5.hexdigest(workflow_data.to_json)}"
    
    if cache_enabled?
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        build_admin_mermaid_diagram(workflow_data)
      end
    else
      build_admin_mermaid_diagram(workflow_data)
    end
  end

  def build_global_workflow_data(tracker)
    # 전역 워크플로우 전환 데이터 수집 (모든 역할 포함)
    transitions = WorkflowTransition.joins(:new_status)
                                  .where(tracker_id: tracker.id)
                                  .includes(:old_status, :new_status, :role)

    # 상태별 그룹화
    status_transitions = transitions.group_by { |t| [t.old_status_id, t.new_status_id] }

    # 상태 정보 수집
    all_status_ids = transitions.map(&:new_status_id).uniq
    all_status_ids += transitions.map(&:old_status_id).compact.uniq
    
    statuses = IssueStatus.where(id: all_status_ids).index_by(&:id)
    
    # 시작 상태 추가
    if transitions.where(old_status_id: 0).exists?
      statuses[0] = OpenStruct.new(id: 0, name: 'New', is_closed: false)
    end

    {
      tracker: {
        id: tracker.id,
        name: tracker.name
      },
      statuses: statuses.values.map { |status|
        {
          id: status.id,
          name: status.name,
          is_closed: status.respond_to?(:is_closed) ? status.is_closed : false,
          color: status_color(status)
        }
      },
      transitions: status_transitions.map { |(old_id, new_id), trans_list|
        roles = trans_list.map { |t| t.role.name }.uniq
        {
          from_id: old_id,
          from_name: old_id == 0 ? 'New' : statuses[old_id]&.name,
          to_id: new_id,
          to_name: statuses[new_id]&.name,
          roles: roles,
          role_count: roles.size
        }
      }
    }
  end

  def generate_mermaid_diagram(workflow_data)
    return '' unless workflow_data && workflow_data[:transitions]

    diagram = ["graph TD"]
    
    # 노드 정의
    workflow_data[:statuses].each do |status|
      node_id = "S#{status[:id]}"
      node_label = status[:name]
      
      if status[:is_closed]
        diagram << "    #{node_id}[#{node_label}]:::closed"
      elsif status[:id] == 0
        diagram << "    #{node_id}((#{node_label})):::start"
      else
        diagram << "    #{node_id}[#{node_label}]:::active"
      end
    end
    
    # 전환 정의 (역할 수에 따른 선 굵기 조정)
    workflow_data[:transitions].each do |transition|
      from_id = "S#{transition[:from_id]}"
      to_id = "S#{transition[:to_id]}"
      
      if transition[:role_count] && transition[:role_count] > 1
        diagram << "    #{from_id} ==> #{to_id}"
      else
        diagram << "    #{from_id} --> #{to_id}"
      end
    end
    
    # 스타일 정의
    diagram << ""
    diagram << "    classDef start fill:#e1f5fe,stroke:#01579b,stroke-width:3px"
    diagram << "    classDef active fill:#f3e5f5,stroke:#4a148c,stroke-width:2px"
    diagram << "    classDef closed fill:#ffebee,stroke:#b71c1c,stroke-width:2px"
    
    diagram.join("\n")
  end

  def build_admin_mermaid_diagram(workflow_data)
    diagram = ["graph TD"]
    
    # 노드 정의
    workflow_data[:statuses].each do |status|
      node_id = "S#{status[:id]}"
      node_label = status[:name]
      
      if status[:is_closed]
        diagram << "    #{node_id}[#{node_label}]:::closed"
      elsif status[:id] == 0
        diagram << "    #{node_id}((#{node_label})):::start"
      else
        diagram << "    #{node_id}[#{node_label}]:::active"
      end
    end
    
    # 전환 정의 (역할 수에 따른 선 굵기 조정)
    workflow_data[:transitions].each do |transition|
      from_id = "S#{transition[:from_id]}"
      to_id = "S#{transition[:to_id]}"
      
      if transition[:role_count] && transition[:role_count] > 1
        diagram << "    #{from_id} ==> #{to_id}"
      else
        diagram << "    #{from_id} --> #{to_id}"
      end
    end
    
    # 스타일 정의
    diagram << ""
    diagram << "    classDef start fill:#e1f5fe,stroke:#01579b,stroke-width:3px"
    diagram << "    classDef active fill:#f3e5f5,stroke:#4a148c,stroke-width:2px"
    diagram << "    classDef closed fill:#ffebee,stroke:#b71c1c,stroke-width:2px"
    
    diagram.join("\n")
  end

  def cache_enabled?
    workflow_viz_settings['cache_diagrams'] == 'true'
  end

  def workflow_viz_settings
    Setting.plugin_redmine_workflow_viz || {}
  end

  def calculate_workflow_statistics
    {
      total_trackers: Tracker.count,
      total_statuses: IssueStatus.count,
      total_transitions: WorkflowTransition.count,
      trackers_with_workflows: Tracker.joins(:workflow_transitions).distinct.count
    }
  end

  def status_color(status)
    return '#4caf50' if status.respond_to?(:is_closed) && status.is_closed
    return '#2196f3' if status.id == 0
    '#ff9800'
  end

  def generate_zip_export(export_data)
    require 'zip'
    
    zip_data = Zip::OutputStream.write_buffer do |zip|
      export_data.each do |tracker_name, data|
        # Mermaid 다이어그램 파일
        zip.put_next_entry("#{tracker_name.parameterize}_diagram.mmd")
        zip.write(data[:mermaid])
        
        # JSON 데이터 파일
        zip.put_next_entry("#{tracker_name.parameterize}_data.json")
        zip.write(JSON.pretty_generate(data[:data]))
      end
      
      # README 파일 추가
      zip.put_next_entry("README.txt")
      zip.write("Redmine Workflow Visualization Export\n")
      zip.write("Generated at: #{Time.current}\n")
      zip.write("Total trackers: #{export_data.size}\n\n")
      zip.write("Files included:\n")
      export_data.each do |tracker_name, _|
        zip.write("- #{tracker_name.parameterize}_diagram.mmd (Mermaid diagram)\n")
        zip.write("- #{tracker_name.parameterize}_data.json (Raw workflow data)\n")
      end
    end
    
    zip_data.string
  rescue LoadError
    # ZIP 라이브러리가 없는 경우 JSON으로 대체
    JSON.pretty_generate(export_data)
  end
end
