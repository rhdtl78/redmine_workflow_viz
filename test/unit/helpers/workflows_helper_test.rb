require File.expand_path('../../../test_helper', __FILE__)

class WorkflowVizHelperTest < ActionView::TestCase
  include WorkflowVizHelper
  
  def setup
    setup_workflow_viz_test_data
  end
  
  def test_generate_workflow_mermaid_graph_with_valid_role_and_tracker
    # Create a workflow
    workflow = WorkflowTransition.create!(
      role: @role,
      tracker: @tracker,
      old_status: @status_new,
      new_status: @status_resolved
    )
    
    result = generate_workflow_mermaid_graph(@role, @tracker)
    
    assert_not_empty result
    assert_includes result, 'mermaid'
    assert_includes result, 'graph TD'
    assert_includes result, @status_new.name.gsub(/[^a-zA-Z0-9]/, '_')
    assert_includes result, @status_resolved.name.gsub(/[^a-zA-Z0-9]/, '_')
  end
  
  def test_generate_workflow_mermaid_graph_with_nil_role
    result = generate_workflow_mermaid_graph(nil, @tracker)
    assert_equal "", result
  end
  
  def test_generate_workflow_mermaid_graph_with_nil_tracker
    result = generate_workflow_mermaid_graph(@role, nil)
    assert_equal "", result
  end
  
  def test_generate_workflow_mermaid_graph_with_no_workflows
    # Role and tracker exist but no workflows
    result = generate_workflow_mermaid_graph(@role, @tracker)
    assert_equal "", result
  end
  
  def test_sanitize_mermaid_name
    helper = Object.new
    helper.extend(WorkflowVizHelper)
    
    # Test various input formats
    assert_equal "New_Issue", helper.send(:sanitize_mermaid_name, "New Issue")
    assert_equal "In_Progress", helper.send(:sanitize_mermaid_name, "In-Progress")
    assert_equal "Resolved", helper.send(:sanitize_mermaid_name, "Resolved")
    assert_equal "unknown", helper.send(:sanitize_mermaid_name, nil)
  end
  
  def test_generate_mermaid_definition
    # Create workflows
    WorkflowTransition.create!(
      role: @role,
      tracker: @tracker,
      old_status: @status_new,
      new_status: @status_resolved
    )
    
    workflows = WorkflowTransition.where(role_id: @role.id, tracker_id: @tracker.id)
    helper = Object.new
    helper.extend(WorkflowVizHelper)
    
    definition = helper.send(:generate_mermaid_definition, workflows)
    
    assert_includes definition, "graph TD"
    assert_includes definition, "-->"
  end
end
