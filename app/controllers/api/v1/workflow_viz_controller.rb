class Api::V1::WorkflowVizController < ApplicationController
  before_action :require_login
  before_action :find_project, only: [:index, :show]
  
  accept_api_auth :index, :show, :mermaid_data, :workflow_json

  def index
    @trackers = @project ? @project.trackers : Tracker.all
    
    respond_to do |format|
      format.api do
        render json: {
          project: @project ? { id: @project.id, name: @project.name } : nil,
          trackers: @trackers.map { |t|
            {
              id: t.id,
              name: t.name,
              workflow_url: api_v1_workflow_viz_url(t.id)
            }
          }
        }
      end
    end
  end

  def show
    @tracker = Tracker.find(params[:id])
    @workflow_data = generate_workflow_data(@tracker)
    
    respond_to do |format|
      format.api do
        render json: {
          tracker: {
            id: @tracker.id,
            name: @tracker.name
          },
          project: @project ? { id: @project.id, name: @project.name } : nil,
          workflow: @workflow_data,
          mermaid_diagram: generate_mermaid_diagram(@workflow_data),
          generated_at: Time.current.iso8601
        }
      end
    end
  end

  def mermaid_data
    tracker_id = params[:tracker_id]
    project_id = params[:project_id]
    
    if tracker_id
      @tracker = Tracker.find(tracker_id)
      @workflow_data = generate_workflow_data(@tracker)
      @mermaid_diagram = generate_mermaid_diagram(@workflow_data)
      
      respond_to do |format|
        format.api do
          render json: {
            tracker_id: @tracker.id,
            tracker_name: @tracker.name,
            project_id: project_id,
            mermaid_code: @mermaid_diagram,
            diagram_type: params[:diagram_type] || 'flowchart',
            theme: params[:theme] || 'default',
            generated_at: Time.current.iso8601
          }
        end
      end
    else
      respond_to do |format|
        format.api do
          render json: { error: 'tracker_id parameter is required' }, status: :bad_request
        end
      end
    end
  end

  def workflow_json
    tracker_id = params[:tracker_id]
    
    if tracker_id
      @tracker = Tracker.find(tracker_id)
      @workflow_data = generate_workflow_data(@tracker)
      
      respond_to do |format|
        format.api do
          render json: {
            tracker: {
              id: @tracker.id,
              name: @tracker.name
            },
            workflow_data: @workflow_data,
            metadata: {
              status_count: @workflow_data[:statuses].size,
              transition_count: @workflow_data[:transitions].size,
              generated_at: Time.current.iso8601,
              api_version: 'v1'
            }
          }
        end
      end
    else
      respond_to do |format|
        format.api do
          render json: { error: 'tracker_id parameter is required' }, status: :bad_request
        end
      end
    end
  end

  private

  def find_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_api_errors(['Project not found'], :not_found)
  end

  def generate_workflow_data(tracker)
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
            role_id: transition.role_id,
            role_name: transition.role.name
          }
        }
      }.uniq { |t| [t[:from_id], t[:to_id], t[:role_id]] }
    }
  end

  def generate_mermaid_diagram(workflow_data)
    return '' unless workflow_data && workflow_data[:transitions]

    diagram_type = params[:diagram_type] || 'flowchart'
    
    case diagram_type
    when 'stateDiagram-v2'
      generate_state_diagram(workflow_data)
    else
      generate_flowchart_diagram(workflow_data)
    end
  end

  def generate_flowchart_diagram(workflow_data)
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
      
      if params[:show_roles] == 'true'
        diagram << "    #{from_id} -->|#{transition[:role_name]}| #{to_id}"
      else
        diagram << "    #{from_id} --> #{to_id}"
      end
    end
    
    # 스타일 정의
    diagram << ""
    diagram << "    classDef start fill:#e1f5fe,stroke:#01579b,stroke-width:2px"
    diagram << "    classDef active fill:#f3e5f5,stroke:#4a148c,stroke-width:2px"
    diagram << "    classDef closed fill:#ffebee,stroke:#b71c1c,stroke-width:2px"
    
    diagram.join("\n")
  end

  def generate_state_diagram(workflow_data)
    diagram = ["stateDiagram-v2"]
    
    # 상태 전환 정의
    workflow_data[:transitions].each do |transition|
      from_name = transition[:from_name].gsub(/\s+/, '_')
      to_name = transition[:to_name].gsub(/\s+/, '_')
      
      if params[:show_roles] == 'true'
        diagram << "    #{from_name} --> #{to_name} : #{transition[:role_name]}"
      else
        diagram << "    #{from_name} --> #{to_name}"
      end
    end
    
    # 종료 상태 정의
    workflow_data[:statuses].select { |s| s[:is_closed] }.each do |status|
      status_name = status[:name].gsub(/\s+/, '_')
      diagram << "    #{status_name} --> [*]"
    end
    
    diagram.join("\n")
  end

  def status_color(status)
    return '#4caf50' if status.respond_to?(:is_closed) && status.is_closed
    return '#2196f3' if status.id == 0
    '#ff9800'
  end
end
