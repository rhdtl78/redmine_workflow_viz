# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# Add plugin-specific test helpers here
class ActiveSupport::TestCase
  # Plugin-specific fixtures can be loaded here
  # fixtures :plugin_specific_table
  
  # Helper methods for workflow visualization tests
  def create_test_workflow(tracker, statuses = nil, roles = nil)
    statuses ||= IssueStatus.limit(3)
    roles ||= Role.limit(2)
    
    transitions = []
    
    # Create initial transition from "New" (id: 0) to first status
    roles.each do |role|
      transitions << WorkflowTransition.create!(
        tracker_id: tracker.id,
        role_id: role.id,
        old_status_id: 0,
        new_status_id: statuses.first.id
      )
    end
    
    # Create transitions between statuses
    statuses.each_with_index do |status, index|
      next_status = statuses[index + 1]
      next unless next_status
      
      roles.each do |role|
        transitions << WorkflowTransition.create!(
          tracker_id: tracker.id,
          role_id: role.id,
          old_status_id: status.id,
          new_status_id: next_status.id
        )
      end
    end
    
    transitions
  end
  
  def cleanup_test_workflows
    WorkflowTransition.delete_all
  end
  
  def assert_valid_mermaid_diagram(diagram_code)
    assert_not_nil diagram_code
    assert diagram_code.is_a?(String)
    assert diagram_code.length > 0
    
    # Check for basic Mermaid syntax
    assert(
      diagram_code.include?('graph TD') || diagram_code.include?('stateDiagram-v2'),
      "Diagram should contain valid Mermaid syntax"
    )
  end
  
  def assert_valid_workflow_data(workflow_data)
    assert_not_nil workflow_data
    assert workflow_data.key?(:tracker)
    assert workflow_data.key?(:statuses)
    assert workflow_data.key?(:transitions)
    
    assert workflow_data[:tracker].key?(:id)
    assert workflow_data[:tracker].key?(:name)
    
    assert workflow_data[:statuses].is_a?(Array)
    assert workflow_data[:transitions].is_a?(Array)
    
    # Validate status structure
    workflow_data[:statuses].each do |status|
      assert status.key?(:id)
      assert status.key?(:name)
      assert status.key?(:is_closed)
      assert status.key?(:color)
    end
    
    # Validate transition structure
    workflow_data[:transitions].each do |transition|
      assert transition.key?(:from_id)
      assert transition.key?(:from_name)
      assert transition.key?(:to_id)
      assert transition.key?(:to_name)
    end
  end
  
  def mock_plugin_settings(settings = {})
    default_settings = {
      'default_diagram_type' => 'flowchart',
      'show_status_colors' => 'true',
      'enable_export' => 'true',
      'mermaid_theme' => 'default',
      'max_diagram_width' => '1200',
      'cache_diagrams' => 'false',
      'show_role_labels' => 'true',
      'enable_fullscreen' => 'true'
    }
    
    Setting.stubs(:plugin_redmine_workflow_viz).returns(default_settings.merge(settings))
  end
end

# Mock classes for testing if needed
class MockWorkflowTransition
  attr_accessor :tracker_id, :role_id, :old_status_id, :new_status_id, :role, :old_status, :new_status
  
  def initialize(attributes = {})
    attributes.each do |key, value|
      send("#{key}=", value)
    end
  end
end
