require File.expand_path('../../../test_helper', __FILE__)

class Api::V1::WorkflowVizControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :trackers, :issue_statuses, :workflows, :enumerations

  def setup
    @project = Project.find(1)
    @tracker = @project.trackers.first
    @user = User.find(2)
    @request.session[:user_id] = @user.id
  end

  def test_index_should_return_trackers_list
    get :index, params: { project_id: @project.id, format: 'json' }
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('project')
    assert json_response.key?('trackers')
    assert_equal @project.id, json_response['project']['id']
    assert json_response['trackers'].is_a?(Array)
  end

  def test_index_without_project_should_return_all_trackers
    get :index, params: { format: 'json' }
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_nil json_response['project']
    assert json_response['trackers'].is_a?(Array)
  end

  def test_show_should_return_workflow_data
    get :show, params: { id: @tracker.id, format: 'json' }
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('tracker')
    assert json_response.key?('workflow')
    assert json_response.key?('mermaid_diagram')
    assert json_response.key?('generated_at')
    assert_equal @tracker.id, json_response['tracker']['id']
  end

  def test_show_with_project_should_include_project_info
    get :show, params: { 
      id: @tracker.id, 
      project_id: @project.id, 
      format: 'json' 
    }
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('project')
    assert_equal @project.id, json_response['project']['id']
  end

  def test_mermaid_data_should_return_diagram_code
    get :mermaid_data, params: { 
      tracker_id: @tracker.id, 
      format: 'json' 
    }
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('tracker_id')
    assert json_response.key?('mermaid_code')
    assert json_response.key?('diagram_type')
    assert json_response.key?('generated_at')
    assert_equal @tracker.id, json_response['tracker_id']
  end

  def test_mermaid_data_with_custom_parameters
    get :mermaid_data, params: { 
      tracker_id: @tracker.id,
      diagram_type: 'stateDiagram-v2',
      theme: 'dark',
      show_roles: 'true',
      format: 'json' 
    }
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'stateDiagram-v2', json_response['diagram_type']
    assert_equal 'dark', json_response['theme']
  end

  def test_mermaid_data_without_tracker_id_should_return_error
    get :mermaid_data, params: { format: 'json' }
    
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('error')
    assert_match /tracker_id parameter is required/, json_response['error']
  end

  def test_workflow_json_should_return_raw_data
    get :workflow_json, params: { 
      tracker_id: @tracker.id, 
      format: 'json' 
    }
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('tracker')
    assert json_response.key?('workflow_data')
    assert json_response.key?('metadata')
    assert_equal @tracker.id, json_response['tracker']['id']
    assert_equal 'v1', json_response['metadata']['api_version']
  end

  def test_workflow_json_without_tracker_id_should_return_error
    get :workflow_json, params: { format: 'json' }
    
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('error')
    assert_match /tracker_id parameter is required/, json_response['error']
  end

  def test_api_authentication_required
    @request.session[:user_id] = nil
    
    get :index, params: { format: 'json' }
    
    assert_response 401
  end

  def test_invalid_project_should_return_not_found
    get :index, params: { project_id: 999999, format: 'json' }
    
    assert_response 404
  end

  def test_invalid_tracker_should_return_not_found
    get :show, params: { id: 999999, format: 'json' }
    
    assert_response 404
  end

  def test_api_key_authentication
    @request.session[:user_id] = nil
    @user.api_key = 'test_api_key'
    @user.save!
    
    get :index, params: { 
      format: 'json',
      key: 'test_api_key'
    }
    
    assert_response :success
  end

  def test_content_type_headers
    get :index, params: { format: 'json' }
    
    assert_response :success
    assert_equal 'application/json', response.content_type
    assert response.headers['Content-Type'].include?('application/json')
  end

  def test_cors_headers_if_configured
    # This test would be relevant if CORS is configured
    get :index, params: { format: 'json' }
    
    assert_response :success
    # Add CORS header assertions if needed
  end
end
