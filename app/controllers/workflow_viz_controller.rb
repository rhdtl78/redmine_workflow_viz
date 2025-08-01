class WorkflowVizController < ApplicationController
  before_action :find_project
  before_action :authorize, except: [:index]
  before_action :authorize_manage, only: [:update_settings]
  
  helper :workflow_viz

  def index
    @trackers = @project.trackers
    @selected_tracker = params[:tracker_id] ? Tracker.find(params[:tracker_id]) : @trackers.first
    
    if @selected_tracker
      @workflow_data = generate_workflow_data(@selected_tracker)
      @mermaid_diagram = generate_mermaid_diagram(@workflow_data)
    end
    
    respond_to do |format|
      format.html
      format.json { render json: @workflow_data }
    end
  end

  def show
    @tracker = Tracker.find(params[:id])
    @workflow_data = generate_workflow_data(@tracker)
    @mermaid_diagram = generate_mermaid_diagram(@workflow_data)
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @workflow_data }
    end
  end

  def export
    @tracker = params[:tracker_id] ? Tracker.find(params[:tracker_id]) : @project.trackers.first
    @workflow_data = generate_workflow_data(@tracker)
    @mermaid_diagram = generate_mermaid_diagram(@workflow_data)
    
    respond_to do |format|
      format.svg do
        render plain: @mermaid_diagram, content_type: 'image/svg+xml'
      end
      format.png do
        # PNG 내보내기는 클라이언트 사이드에서 처리
        redirect_to workflow_viz_index_path(@project, tracker_id: @tracker.id, format: :html)
      end
      format.json do
        render json: {
          mermaid: @mermaid_diagram,
          data: @workflow_data
        }
      end
    end
  end

  def update_settings
    if request.post?
      settings = params[:settings] || {}
      Setting.plugin_redmine_workflow_viz = settings
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_workflow_viz_index_path(@project)
    else
      redirect_to project_workflow_viz_index_path(@project)
    end
  end

  def tracker_workflow
    @tracker = Tracker.find(params[:tracker_id])
    @workflow_data = generate_workflow_data(@tracker)
    
    render json: {
      mermaid: generate_mermaid_diagram(@workflow_data),
      data: @workflow_data
    }
  end

  def status_transitions
    @tracker = Tracker.find(params[:tracker_id])
    @transitions = WorkflowTransition.joins(:old_status, :new_status)
                                   .where(tracker_id: @tracker.id)
                                   .includes(:old_status, :new_status, :role)
    
    render json: @transitions.map { |t|
      {
        from: t.old_status&.name || 'New',
        to: t.new_status.name,
        role: t.role.name,
        tracker: t.tracker.name
      }
    }
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_manage
    deny_access unless User.current.allowed_to?(:manage_workflow_viz, @project)
  end

  def generate_workflow_data(tracker)
    cache_key = "workflow_viz_data_#{tracker.id}_#{tracker.updated_at.to_i}"
    
    if cache_enabled?
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        build_workflow_data(tracker)
      end
    else
      build_workflow_data(tracker)
    end
  end

  def generate_mermaid_diagram(workflow_data)
    return '' unless workflow_data && workflow_data[:transitions]

    cache_key = "workflow_viz_mermaid_#{workflow_data[:tracker][:id]}_#{Digest::MD5.hexdigest(workflow_data.to_json)}"
    
    if cache_enabled?
      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        build_mermaid_diagram(workflow_data)
      end
    else
      build_mermaid_diagram(workflow_data)
    end
  end

  def build_workflow_data(tracker)
    # 워크플로우 전환 데이터 수집
    transitions = WorkflowTransition.joins(:new_status)
                                  .where(tracker_id: tracker.id)
                                  .includes(:old_status, :new_status, :role)
                                  .group_by(&:old_status_id)

    # 상태 정보 수집
    statuses = IssueStatus.where(
      id: transitions.values.flatten.map(&:new_status_id).uniq
    ).index_by(&:id)

    # 시작 상태 추가 (old_status_id가 0인 경우)
    if transitions[0]
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
      transitions: transitions.flat_map { |old_status_id, trans_list|
        trans_list.map { |transition|
          {
            from_id: old_status_id,
            from_name: old_status_id == 0 ? 'New' : statuses[old_status_id]&.name,
            to_id: transition.new_status_id,
            to_name: transition.new_status.name,
            role: transition.role.name
          }
        }
      }.uniq { |t| [t[:from_id], t[:to_id]] }
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
    
    # 전환 정의
    workflow_data[:transitions].each do |transition|
      from_id = "S#{transition[:from_id]}"
      to_id = "S#{transition[:to_id]}"
      diagram << "    #{from_id} --> #{to_id}"
    end
    
    # 스타일 정의
    diagram << ""
    diagram << "    classDef start fill:#e1f5fe,stroke:#01579b,stroke-width:2px"
    diagram << "    classDef active fill:#f3e5f5,stroke:#4a148c,stroke-width:2px"
    diagram << "    classDef closed fill:#ffebee,stroke:#b71c1c,stroke-width:2px"
    
    diagram.join("\n")
  end

  def build_mermaid_diagram(workflow_data)
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
    
    # 전환 정의
    workflow_data[:transitions].each do |transition|
      from_id = "S#{transition[:from_id]}"
      to_id = "S#{transition[:to_id]}"
      diagram << "    #{from_id} --> #{to_id}"
    end
    
    # 스타일 정의
    diagram << ""
    diagram << "    classDef start fill:#e1f5fe,stroke:#01579b,stroke-width:2px"
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

  def status_color(status)
    return '#4caf50' if status.respond_to?(:is_closed) && status.is_closed
    return '#2196f3' if status.id == 0
    '#ff9800'
  end
end
