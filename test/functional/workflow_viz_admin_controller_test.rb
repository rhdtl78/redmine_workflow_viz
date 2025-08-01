require File.expand_path('../../test_helper', __FILE__)

class WorkflowVizAdminControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :trackers, :issue_statuses, :workflows, :enumerations

  def setup
    @tracker = Tracker.first
    @admin_user = User.find(1) # Admin user
    @regular_user = User.find(2) # Regular user
    @request.session[:user_id] = @admin_user.id
  end

  def test_index_should_show_admin_workflow_visualization
    get :index
    
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:trackers)
    assert_not_nil assigns(:selected_tracker)
    assert_not_nil assigns(:statistics)
  end

  def test_index_with_specific_tracker
    get :index, params: { tracker_id: @tracker.id }
    
    assert_response :success
    assert_equal @tracker, assigns(:selected_tracker)
    assert_not_nil assigns(:workflow_data)
    assert_not_nil assigns(:mermaid_diagram)
  end

  def test_show_tracker_workflow
    get :show, params: { id: @tracker.id }
    
    assert_response :success
    assert_equal @tracker, assigns(:tracker)
    assert_not_nil assigns(:workflow_data)
  end

  def test_show_json_format
    get :show, params: { id: @tracker.id, format: 'json' }
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('tracker')
    assert json_response.key?('statuses')
    assert json_response.key?('transitions')
  end

  def test_global_workflow_ajax
    get :global_workflow, params: { tracker_id: @tracker.id }, xhr: true
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('mermaid')
    assert json_response.key?('data')
  end

  def test_tracker_overview_ajax
    get :tracker_overview, xhr: true
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
    
    if json_response.any?
      first_item = json_response.first
      assert first_item.key?('tracker')
      assert first_item.key?('transition_count')
      assert first_item.key?('status_count')
      assert first_item.key?('role_count')
    end
  end

  def test_bulk_export_json
    get :bulk_export, params: { format: 'json' }
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Hash)
    
    # Should contain data for each tracker
    Tracker.all.each do |tracker|
      if json_response[tracker.name]
        assert json_response[tracker.name].key?('mermaid')
        assert json_response[tracker.name].key?('data')
      end
    end
  end

  def test_bulk_export_zip
    get :bulk_export, params: { format: 'zip' }
    
    assert_response :success
    assert_equal 'application/zip', response.content_type
    assert_match /redmine_workflows_\d{4}-\d{2}-\d{2}\.zip/, 
                 response.headers['Content-Disposition']
  end

  def test_statistics_calculation
    get :index
    
    statistics = assigns(:statistics)
    assert_not_nil statistics
    assert statistics.key?(:total_trackers)
    assert statistics.key?(:total_statuses)
    assert statistics.key?(:total_transitions)
    assert statistics.key?(:trackers_with_workflows)
    
    assert statistics[:total_trackers] >= 0
    assert statistics[:total_statuses] >= 0
    assert statistics[:total_transitions] >= 0
    assert statistics[:trackers_with_workflows] >= 0
  end

  def test_access_denied_for_non_admin
    @request.session[:user_id] = @regular_user.id
    
    get :index
    
    assert_response 403 # Forbidden
  end

  def test_access_denied_without_login
    @request.session[:user_id] = nil
    
    get :index
    
    assert_response 302 # Redirect to login
  end

  def test_tracker_not_found
    get :show, params: { id: 999999 }
    
    assert_response 404
  end

  def test_global_workflow_with_invalid_tracker
    get :global_workflow, params: { tracker_id: 999999 }, xhr: true
    
    assert_response 404
  end

  def test_workflow_data_generation_with_complex_workflow
    # Setup complex workflow for testing
    setup_complex_workflow
    
    get :show, params: { id: @tracker.id }
    
    workflow_data = assigns(:workflow_data)
    assert_not_nil workflow_data
    assert workflow_data[:statuses].size > 0
    assert workflow_data[:transitions].size > 0
    
    # Check that role information is included
    transition_with_roles = workflow_data[:transitions].find { |t| t[:roles] }
    assert_not_nil transition_with_roles if workflow_data[:transitions].any?
  end

  def test_mermaid_diagram_generation
    get :index, params: { tracker_id: @tracker.id }
    
    mermaid_diagram = assigns(:mermaid_diagram)
    assert_not_nil mermaid_diagram
    assert mermaid_diagram.include?('graph TD')
    assert mermaid_diagram.include?('classDef')
  end

  def test_zip_export_fallback_without_zip_library
    # Mock the ZIP library to not be available
    Zip.stubs(:const_defined?).with(:OutputStream).returns(false)
    
    get :bulk_export, params: { format: 'zip' }
    
    # Should fallback to JSON format
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Hash)
  end

  def test_admin_layout_usage
    get :index
    
    assert_response :success
    assert_template layout: 'admin'
  end

  def test_contextual_links_presence
    get :index
    
    assert_response :success
    assert_select '.contextual', count: 1
    assert_select '.contextual a', text: /Bulk Export/
  end

  private

  def setup_complex_workflow
    # Create a more complex workflow for testing
    role1 = Role.find(1)
    role2 = Role.find(2) if Role.count > 1
    
    status_new = IssueStatus.find(1)
    status_assigned = IssueStatus.find(2)
    status_resolved = IssueStatus.find(3)
    
    # Create multiple transitions with different roles
    WorkflowTransition.create!(
      tracker_id: @tracker.id,
      role_id: role1.id,
      old_status_id: 0,
      new_status_id: status_new.id
    )
    
    WorkflowTransition.create!(
      tracker_id: @tracker.id,
      role_id: role1.id,
      old_status_id: status_new.id,
      new_status_id: status_assigned.id
    )
    
    if role2
      WorkflowTransition.create!(
        tracker_id: @tracker.id,
        role_id: role2.id,
        old_status_id: status_new.id,
        new_status_id: status_assigned.id
      )
    end
    
    WorkflowTransition.create!(
      tracker_id: @tracker.id,
      role_id: role1.id,
      old_status_id: status_assigned.id,
      new_status_id: status_resolved.id
    )
  end
end
