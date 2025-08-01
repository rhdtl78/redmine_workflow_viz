# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Plugin test helper for Redmine 6
class ActiveSupport::TestCase
  # Add any plugin-specific test setup here
  
  def setup_workflow_viz_test_data
    # Helper method to set up test data for workflow visualization tests
    @role = Role.find_by(name: 'Manager') || Role.create!(name: 'Test Role', permissions: [:view_issues])
    @tracker = Tracker.find_by(name: 'Bug') || Tracker.create!(name: 'Test Tracker')
    @status_new = IssueStatus.find_by(name: 'New') || IssueStatus.create!(name: 'New')
    @status_resolved = IssueStatus.find_by(name: 'Resolved') || IssueStatus.create!(name: 'Resolved')
  end
end
