module WorkflowVizHelper
  
  def workflow_viz_settings
    Setting.plugin_redmine_workflow_viz || {}
  end

  def default_diagram_type
    workflow_viz_settings['default_diagram_type'] || 'flowchart'
  end

  def show_status_colors?
    workflow_viz_settings['show_status_colors'] == 'true'
  end

  def export_enabled?
    workflow_viz_settings['enable_export'] == 'true'
  end

  def tracker_select_options(trackers, selected_tracker = nil)
    options_from_collection_for_select(
      trackers, 
      :id, 
      :name, 
      selected_tracker&.id
    )
  end

  def status_badge(status)
    css_class = case
                when status[:is_closed]
                  'badge badge-closed'
                when status[:id] == 0
                  'badge badge-start'
                else
                  'badge badge-active'
                end
    
    content_tag :span, status[:name], class: css_class
  end

  def transition_count_badge(count)
    css_class = case count
                when 0
                  'badge badge-secondary'
                when 1..5
                  'badge badge-primary'
                when 6..10
                  'badge badge-warning'
                else
                  'badge badge-danger'
                end
    
    content_tag :span, count, class: css_class
  end

  def mermaid_diagram_container(diagram_id, mermaid_code, options = {})
    container_options = {
      id: "#{diagram_id}_container",
      class: "mermaid-container #{options[:class]}",
      style: options[:style]
    }.compact

    content_tag :div, container_options do
      content_tag(:div, '', 
                  id: diagram_id, 
                  class: 'mermaid', 
                  data: { mermaid: mermaid_code }) +
      content_tag(:div, '', class: 'mermaid-loading', style: 'display: none;') do
        content_tag(:i, '', class: 'fa fa-spinner fa-spin') + ' Loading diagram...'
      end
    end
  end

  def export_buttons(project, tracker)
    return '' unless export_enabled?
    
    buttons = []
    
    buttons << link_to(
      content_tag(:i, '', class: 'fa fa-download') + ' SVG',
      export_project_workflow_viz_path(project, tracker, format: :svg),
      class: 'btn btn-sm btn-outline-primary',
      target: '_blank'
    )
    
    buttons << link_to(
      content_tag(:i, '', class: 'fa fa-image') + ' PNG',
      '#',
      class: 'btn btn-sm btn-outline-secondary export-png',
      data: { tracker_id: tracker.id }
    )
    
    buttons << link_to(
      content_tag(:i, '', class: 'fa fa-code') + ' JSON',
      export_project_workflow_viz_path(project, tracker, format: :json),
      class: 'btn btn-sm btn-outline-info',
      target: '_blank'
    )
    
    content_tag :div, class: 'export-buttons' do
      safe_join(buttons, ' ')
    end
  end

  def workflow_statistics_table(statistics)
    return '' unless statistics
    
    content_tag :table, class: 'table table-sm' do
      content_tag(:tbody) do
        rows = []
        
        rows << content_tag(:tr) do
          content_tag(:td, 'Total Trackers:', class: 'font-weight-bold') +
          content_tag(:td, statistics[:total_trackers])
        end
        
        rows << content_tag(:tr) do
          content_tag(:td, 'Total Statuses:', class: 'font-weight-bold') +
          content_tag(:td, statistics[:total_statuses])
        end
        
        rows << content_tag(:tr) do
          content_tag(:td, 'Total Transitions:', class: 'font-weight-bold') +
          content_tag(:td, statistics[:total_transitions])
        end
        
        rows << content_tag(:tr) do
          content_tag(:td, 'Trackers with Workflows:', class: 'font-weight-bold') +
          content_tag(:td, statistics[:trackers_with_workflows])
        end
        
        safe_join(rows)
      end
    end
  end

  def diagram_type_options
    [
      ['Flowchart', 'flowchart'],
      ['State Diagram', 'stateDiagram-v2']
    ]
  end

  def mermaid_theme_options
    [
      ['Default', 'default'],
      ['Dark', 'dark'],
      ['Forest', 'forest'],
      ['Neutral', 'neutral']
    ]
  end

  def workflow_breadcrumb(project = nil, tracker = nil)
    breadcrumb = []
    
    if project
      breadcrumb << link_to(project.name, project_path(project))
      breadcrumb << link_to('Workflow Visualization', 
                           project_workflow_viz_index_path(project))
    else
      breadcrumb << link_to('Administration', admin_path)
      breadcrumb << 'Workflow Visualization'
    end
    
    if tracker
      breadcrumb << tracker.name
    end
    
    safe_join(breadcrumb, ' » ')
  end

  def javascript_include_mermaid
    javascript_include_tag 'https://cdn.jsdelivr.net/npm/mermaid@11.9.0/dist/mermaid.min.js'
  end

  def render_workflow_legend
    content_tag :div, class: 'workflow-legend' do
      legend_items = []
      
      legend_items << content_tag(:div, class: 'legend-item') do
        content_tag(:span, '', class: 'legend-color start') +
        content_tag(:span, 'Start Status', class: 'legend-label')
      end
      
      legend_items << content_tag(:div, class: 'legend-item') do
        content_tag(:span, '', class: 'legend-color active') +
        content_tag(:span, 'Active Status', class: 'legend-label')
      end
      
      legend_items << content_tag(:div, class: 'legend-item') do
        content_tag(:span, '', class: 'legend-color closed') +
        content_tag(:span, 'Closed Status', class: 'legend-label')
      end
      
      safe_join(legend_items)
    end
  end
end
