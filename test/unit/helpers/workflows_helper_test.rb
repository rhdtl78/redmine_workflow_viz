require File.expand_path('../../../test_helper', __FILE__)

class WorkflowsHelperTest < ActionView::TestCase
  include WorkflowsHelper
  
  def setup
    setup_workflow_viz_test_data
  end
  
  def test_generate_graph_with_valid_role_and_tracker
    # Create a workflow
    workflow = WorkflowTransition.create!(
      role: @role,
      tracker: @tracker,
      old_status: @status_new,
      new_status: @status_resolved
    )
    
    result = generate_graph(@role, @tracker)
    
    assert_not_empty result
    assert_includes result, 'https://chart.googleapis.com/chart'
    assert_includes result, 'cht=gv'
  end
  
  def test_generate_graph_with_nil_role
    result = generate_graph(nil, @tracker)
    assert_equal "", result
  end
  
  def test_generate_graph_with_nil_tracker
    result = generate_graph(@role, nil)
    assert_equal "", result
  end
  
  def test_generate_graph_with_no_workflows
    # Role and tracker exist but no workflows
    result = generate_graph(@role, @tracker)
    assert_equal "", result
  end
  
  private
  
  def test_sanitize_status_name
    helper = Object.new
    helper.extend(WorkflowsHelper)
    
    # Test private method through reflection if needed
    # This is just a placeholder for the private method test
    assert true
  end
end
