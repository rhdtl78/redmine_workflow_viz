# Redmine Workflow Visualization Plugin - Installation Guide

## Prerequisites

Before installing the plugin, ensure your system meets the following requirements:

- **Redmine**: Version 6.0 or higher
- **Ruby**: Version 3.0 or higher
- **Rails**: Version 7.0 or higher
- **Database**: PostgreSQL, MySQL, or SQLite3 (as supported by Redmine)
- **Browser**: Modern browser with JavaScript enabled

## Installation Steps

### 1. Download the Plugin

Navigate to your Redmine plugins directory and clone the repository:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/kether/redmine_workflow_viz.git
```

### 2. Install Dependencies (Optional)

If you want to enable ZIP export functionality, install the `rubyzip` gem:

```bash
cd /path/to/redmine
echo 'gem "rubyzip"' >> Gemfile.local
bundle install
```

### 3. Run Database Migrations

Currently, this plugin doesn't require database migrations, but it's good practice to run the migration command:

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### 4. Restart Redmine

Restart your Redmine server to load the plugin:

```bash
# For Passenger
touch tmp/restart.txt

# For Puma
kill -USR1 $(cat tmp/pids/server.pid)

# For other servers, restart according to your setup
```

### 5. Verify Installation

1. Log in to Redmine as an administrator
2. Go to **Administration** → **Plugins**
3. Verify that "Redmine Workflow Visualization Plugin" appears in the list
4. The status should show as "Installed"

### 6. Configure Plugin Settings

1. In the plugins list, click **Configure** next to the plugin name
2. Adjust the following settings as needed:
   - **Default Diagram Type**: Choose between flowchart and state diagram
   - **Show Status Colors**: Enable/disable color coding
   - **Enable Export**: Allow users to export diagrams
   - **Mermaid Theme**: Select the default theme
   - **Maximum Diagram Width**: Set diagram width limit
   - **Cache Diagrams**: Enable caching for better performance
   - **Show Role Labels**: Display role names on transitions
   - **Enable Fullscreen**: Allow fullscreen viewing

3. Click **Apply** to save the settings

### 7. Set Up Permissions

1. Go to **Administration** → **Roles and permissions**
2. For each role that should access workflow visualization:
   - Check **View workflow visualization** for basic access
   - Check **Manage workflow visualization** for advanced features
3. Save the changes

## Post-Installation Verification

### Test Basic Functionality

1. Navigate to any project
2. Click **Workflow Visualization** in the project menu
3. Select a tracker from the dropdown
4. Verify that the workflow diagram appears
5. Test the zoom and export functions

### Test Admin Features

1. Go to **Administration** → **Workflow Visualization**
2. Verify that global statistics are displayed
3. Test the bulk export functionality
4. Check the tracker overview feature

### Test API Access

Test the API endpoints using curl or a similar tool:

```bash
# Get workflow data for tracker ID 1
curl -H "Accept: application/json" \
     -u username:password \
     http://your-redmine-url/api/v1/workflow_viz/1.json

# Get Mermaid diagram code
curl -H "Accept: application/json" \
     -u username:password \
     "http://your-redmine-url/api/v1/workflow_viz/mermaid_data.json?tracker_id=1"
```

## Troubleshooting

### Plugin Not Appearing

If the plugin doesn't appear in the plugins list:

1. Check file permissions:
   ```bash
   chmod -R 755 /path/to/redmine/plugins/redmine_workflow_viz
   ```

2. Verify the plugin directory structure:
   ```bash
   ls -la /path/to/redmine/plugins/redmine_workflow_viz/
   ```

3. Check Redmine logs for errors:
   ```bash
   tail -f /path/to/redmine/log/production.log
   ```

### Diagrams Not Rendering

If workflow diagrams don't appear:

1. Check browser console for JavaScript errors
2. Verify that Mermaid.js is loading from the CDN
3. Ensure workflows are configured for the selected tracker
4. Check network connectivity to cdn.jsdelivr.net

### Permission Errors

If users can't access the plugin:

1. Verify that the **workflow_viz** module is enabled for the project
2. Check that appropriate permissions are assigned to user roles
3. Ensure users are members of the project with correct roles

### Performance Issues

If the plugin is slow:

1. Enable diagram caching in plugin settings
2. Check database performance for workflow queries
3. Consider upgrading to a faster server or database

### Export Not Working

If export functions fail:

1. For ZIP export: Ensure `rubyzip` gem is installed
2. For PNG export: Check browser compatibility and JavaScript console
3. For SVG export: Verify server response and content type

## Uninstallation

To remove the plugin:

1. Stop Redmine server
2. Remove the plugin directory:
   ```bash
   rm -rf /path/to/redmine/plugins/redmine_workflow_viz
   ```
3. Run migration rollback (if applicable):
   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_workflow_viz VERSION=0 RAILS_ENV=production
   ```
4. Restart Redmine server

## Advanced Configuration

### Custom Themes

To add custom Mermaid.js themes, modify the helper file:

```ruby
# In app/helpers/workflow_viz_helper.rb
def mermaid_theme_options
  [
    ['Default', 'default'],
    ['Dark', 'dark'],
    ['Forest', 'forest'],
    ['Neutral', 'neutral'],
    ['Custom Theme', 'custom']  # Add your custom theme
  ]
end
```

### Custom Styling

Override default styles by adding CSS to your Redmine theme:

```css
/* Custom workflow visualization styles */
.workflow-diagram-main {
  border: 2px solid #your-color;
  border-radius: 10px;
}

.mermaid-container {
  background: #your-background;
}
```

### Caching Configuration

For better performance, configure Redis or Memcached for Rails caching:

```ruby
# In config/environments/production.rb
config.cache_store = :redis_cache_store, { url: "redis://localhost:6379/1" }
```

## Support

If you encounter issues during installation:

1. Check the [GitHub Issues](https://github.com/kether/redmine_workflow_viz/issues)
2. Review the [README.md](README.md) for additional information
3. Post questions in the Redmine community forums
4. Contact the plugin maintainer

## Next Steps

After successful installation:

1. Configure workflows for your trackers if not already done
2. Train users on the new visualization features
3. Set up regular backups that include plugin settings
4. Monitor performance and adjust caching settings as needed
5. Consider contributing improvements back to the project
