require File.expand_path('../../test_helper', __FILE__)

class WorkflowVizHelperTest < Redmine::HelperTest
  include WorkflowVizHelper
  
  fixtures :trackers, :issue_statuses

  def setup
    @tracker = Tracker.first
    @status_new = IssueStatus.find(1)
    @status_closed = IssueStatus.find(5)
  end

  def test_tracker_select_options
    trackers = Tracker.limit(3)
    selected_tracker = trackers.first
    
    options = tracker_select_options(trackers, selected_tracker)
    
    assert_match /option.*selected.*#{selected_tracker.name}/, options
    assert_match /#{trackers.last.name}/, options
  end

  def test_status_badge_for_start_status
    status = { id: 0, name: 'New', is_closed: false }
    
    badge = status_badge(status)
    
    assert_match /badge-start/, badge
    assert_match /New/, badge
  end

  def test_status_badge_for_active_status
    status = { id: 1, name: 'In Progress', is_closed: false }
    
    badge = status_badge(status)
    
    assert_match /badge-active/, badge
    assert_match /In Progress/, badge
  end

  def test_status_badge_for_closed_status
    status = { id: 5, name: 'Closed', is_closed: true }
    
    badge = status_badge(status)
    
    assert_match /badge-closed/, badge
    assert_match /Closed/, badge
  end

  def test_transition_count_badge_low
    badge = transition_count_badge(3)
    
    assert_match /badge-primary/, badge
    assert_match /3/, badge
  end

  def test_transition_count_badge_medium
    badge = transition_count_badge(7)
    
    assert_match /badge-warning/, badge
    assert_match /7/, badge
  end

  def test_transition_count_badge_high
    badge = transition_count_badge(15)
    
    assert_match /badge-danger/, badge
    assert_match /15/, badge
  end

  def test_mermaid_diagram_container
    diagram_id = 'test-diagram'
    mermaid_code = 'graph TD; A --> B'
    
    container = mermaid_diagram_container(diagram_id, mermaid_code)
    
    assert_match /id="#{diagram_id}_container"/, container
    assert_match /class="mermaid-container"/, container
    assert_match /id="#{diagram_id}"/, container
    assert_match /class="mermaid"/, container
    assert_match /data-mermaid="#{Regexp.escape(mermaid_code)}"/, container
  end

  def test_mermaid_diagram_container_with_options
    diagram_id = 'test-diagram'
    mermaid_code = 'graph TD; A --> B'
    options = { class: 'custom-class', style: 'height: 300px;' }
    
    container = mermaid_diagram_container(diagram_id, mermaid_code, options)
    
    assert_match /class="mermaid-container custom-class"/, container
    assert_match /style="height: 300px;"/, container
  end

  def test_workflow_statistics_table
    statistics = {
      total_trackers: 5,
      total_statuses: 8,
      total_transitions: 25,
      trackers_with_workflows: 4
    }
    
    table = workflow_statistics_table(statistics)
    
    assert_match /Total Trackers.*5/, table
    assert_match /Total Statuses.*8/, table
    assert_match /Total Transitions.*25/, table
    assert_match /Trackers with Workflows.*4/, table
  end

  def test_workflow_statistics_table_with_nil
    table = workflow_statistics_table(nil)
    
    assert_equal '', table
  end

  def test_diagram_type_options
    options = diagram_type_options
    
    assert_equal 2, options.size
    assert_includes options, ['Flowchart', 'flowchart']
    assert_includes options, ['State Diagram', 'stateDiagram-v2']
  end

  def test_mermaid_theme_options
    options = mermaid_theme_options
    
    assert_equal 4, options.size
    assert_includes options, ['Default', 'default']
    assert_includes options, ['Dark', 'dark']
    assert_includes options, ['Forest', 'forest']
    assert_includes options, ['Neutral', 'neutral']
  end

  def test_render_workflow_legend
    legend = render_workflow_legend
    
    assert_match /workflow-legend/, legend
    assert_match /legend-color start/, legend
    assert_match /legend-color active/, legend
    assert_match /legend-color closed/, legend
    assert_match /Start Status/, legend
    assert_match /Active Status/, legend
    assert_match /Closed Status/, legend
  end

  def test_workflow_viz_settings_default_values
    # Mock Setting.plugin_redmine_workflow_viz to return nil
    Setting.stubs(:plugin_redmine_workflow_viz).returns(nil)
    
    assert_equal({}, workflow_viz_settings)
    assert_equal 'flowchart', default_diagram_type
    assert_equal false, show_status_colors?
    assert_equal false, export_enabled?
  end

  def test_workflow_viz_settings_with_values
    settings = {
      'default_diagram_type' => 'stateDiagram-v2',
      'show_status_colors' => 'true',
      'enable_export' => 'true'
    }
    
    Setting.stubs(:plugin_redmine_workflow_viz).returns(settings)
    
    assert_equal settings, workflow_viz_settings
    assert_equal 'stateDiagram-v2', default_diagram_type
    assert_equal true, show_status_colors?
    assert_equal true, export_enabled?
  end
end
