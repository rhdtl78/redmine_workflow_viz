require File.expand_path('../../test_helper', __FILE__)

class WorkflowVizControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :trackers, :issue_statuses, :workflows, :enumerations

  def setup
    @project = Project.find(1)
    @tracker = @project.trackers.first
    @user = User.find(2)
    @request.session[:user_id] = @user.id
  end

  def test_index_should_show_workflow_visualization
    get :index, params: { project_id: @project.id }
    
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:trackers)
    assert_not_nil assigns(:selected_tracker)
  end

  def test_index_with_specific_tracker
    get :index, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id 
    }
    
    assert_response :success
    assert_equal @tracker, assigns(:selected_tracker)
    assert_not_nil assigns(:workflow_data)
    assert_not_nil assigns(:mermaid_diagram)
  end

  def test_index_json_format
    get :index, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id,
      format: 'json'
    }
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('tracker')
    assert json_response.key?('statuses')
    assert json_response.key?('transitions')
  end

  def test_show_tracker_workflow
    get :show, params: { 
      project_id: @project.id, 
      id: @tracker.id 
    }
    
    assert_response :success
    assert_equal @tracker, assigns(:tracker)
    assert_not_nil assigns(:workflow_data)
  end

  def test_export_svg_format
    get :export, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id,
      format: 'svg'
    }
    
    assert_response :success
    assert_equal 'image/svg+xml', response.content_type
  end

  def test_export_json_format
    get :export, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id,
      format: 'json'
    }
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('mermaid')
    assert json_response.key?('data')
  end

  def test_tracker_workflow_ajax
    get :tracker_workflow, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id 
    }, xhr: true
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('mermaid')
    assert json_response.key?('data')
  end

  def test_status_transitions_ajax
    get :status_transitions, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id 
    }, xhr: true
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
  end

  def test_update_settings_post
    new_settings = {
      'default_diagram_type' => 'stateDiagram-v2',
      'show_status_colors' => 'false',
      'enable_export' => 'true'
    }
    
    post :update_settings, params: { 
      project_id: @project.id,
      settings: new_settings
    }
    
    assert_response 302 # redirect
    assert_redirected_to project_workflow_viz_index_path(@project)
    assert_equal 'Successful update.', flash[:notice]
    
    # Verify settings were saved
    saved_settings = Setting.plugin_redmine_workflow_viz
    assert_equal 'stateDiagram-v2', saved_settings['default_diagram_type']
    assert_equal 'false', saved_settings['show_status_colors']
    assert_equal 'true', saved_settings['enable_export']
  end

  def test_update_settings_get_redirects
    get :update_settings, params: { project_id: @project.id }
    
    assert_response 302
    assert_redirected_to project_workflow_viz_index_path(@project)
  end

  def test_update_settings_requires_manage_permission
    # Remove manage permission from user
    @user.members.first.roles.first.remove_permission!(:manage_workflow_viz)
    
    post :update_settings, params: { 
      project_id: @project.id,
      settings: { 'test' => 'value' }
    }
    
    assert_response 403 # Forbidden
  end

  def test_caching_enabled_when_setting_is_true
    Setting.plugin_redmine_workflow_viz = { 'cache_diagrams' => 'true' }
    
    # Mock Rails.cache to verify it's being used
    Rails.cache.expects(:fetch).at_least_once.returns({})
    
    get :index, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id 
    }
    
    assert_response :success
  end

  def test_caching_disabled_when_setting_is_false
    Setting.plugin_redmine_workflow_viz = { 'cache_diagrams' => 'false' }
    
    # Mock Rails.cache to verify it's NOT being used
    Rails.cache.expects(:fetch).never
    
    get :index, params: { 
      project_id: @project.id, 
      tracker_id: @tracker.id 
    }
    
    assert_response :success
  end

  def test_access_denied_without_permission
    @request.session[:user_id] = nil
    
    get :index, params: { project_id: @project.id }
    
    assert_response 302 # redirect to login
  end

  def test_project_not_found
    get :index, params: { project_id: 999999 }
    
    assert_response 404
  end

  def test_tracker_not_found
    get :show, params: { 
      project_id: @project.id, 
      id: 999999 
    }
    
    assert_response 404
  end

  private

  def setup_workflow_transitions
    # 테스트용 워크플로우 전환 설정
    role = Role.find(1)
    status_new = IssueStatus.find(1)
    status_assigned = IssueStatus.find(2)
    status_resolved = IssueStatus.find(3)
    
    WorkflowTransition.create!(
      tracker_id: @tracker.id,
      role_id: role.id,
      old_status_id: 0,
      new_status_id: status_new.id
    )
    
    WorkflowTransition.create!(
      tracker_id: @tracker.id,
      role_id: role.id,
      old_status_id: status_new.id,
      new_status_id: status_assigned.id
    )
    
    WorkflowTransition.create!(
      tracker_id: @tracker.id,
      role_id: role.id,
      old_status_id: status_assigned.id,
      new_status_id: status_resolved.id
    )
  end
end
