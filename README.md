# Redmine Workflow Visualization Plugin

A comprehensive Redmine plugin that provides interactive workflow visualization using Mermaid.js diagrams.

## Features

### 🎯 Core Features
- **Interactive Workflow Diagrams**: Visualize issue workflows as flowcharts or state diagrams
- **Multiple Diagram Types**: Support for Mermaid.js flowcharts and state diagrams
- **Project-Level Integration**: Seamlessly integrated into project menus
- **Admin Dashboard**: Global workflow management and overview
- **Export Capabilities**: Export diagrams as SVG, PNG, or JSON

### 🎨 Visualization Features
- **Dynamic Diagram Generation**: Real-time diagram updates based on workflow changes
- **Status Color Coding**: Different colors for start, active, and closed statuses
- **Role-Based Transitions**: Display role information on workflow transitions
- **Zoom and Pan**: Interactive diagram controls for better navigation
- **Fullscreen Mode**: Distraction-free diagram viewing
- **Multiple Themes**: Support for various Mermaid.js themes

### 🔧 Technical Features
- **RESTful API**: Complete API for programmatic access
- **Caching Support**: Optional diagram caching for improved performance
- **Multi-language Support**: English and Korean localization included
- **Responsive Design**: Mobile-friendly interface
- **Accessibility**: WCAG compliant design

## Requirements

- **Redmine**: 6.0 or higher
- **Ruby**: 3.0 or higher
- **Rails**: 7.0 or higher
- **Browser**: Modern browser with JavaScript enabled

## Installation

1. **Download the plugin**:
   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/kether/redmine_workflow_viz.git
   ```

2. **Install dependencies** (if any):
   ```bash
   cd redmine_workflow_viz
   bundle install
   ```

3. **Run database migrations** (if any):
   ```bash
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```

4. **Restart Redmine**:
   ```bash
   # For Passenger
   touch tmp/restart.txt
   
   # For other servers, restart according to your setup
   ```

5. **Configure the plugin**:
   - Go to **Administration** → **Plugins**
   - Find "Redmine Workflow Visualization Plugin"
   - Click **Configure** to adjust settings

## Usage

### Project-Level Workflow Visualization

1. Navigate to any project
2. Click **Workflow Visualization** in the project menu
3. Select a tracker from the dropdown
4. View the interactive workflow diagram
5. Use controls to zoom, pan, or switch to fullscreen mode

### Admin-Level Workflow Management

1. Go to **Administration** → **Workflow Visualization**
2. View global workflow statistics
3. Select trackers to see comprehensive workflow diagrams
4. Export workflows in bulk
5. Access tracker overview for quick insights

### API Usage

The plugin provides a RESTful API for programmatic access:

```bash
# Get workflow data for a specific tracker
GET /api/v1/workflow_viz/{tracker_id}.json

# Get Mermaid diagram code
GET /api/v1/workflow_viz/mermaid_data.json?tracker_id={tracker_id}

# Get raw workflow JSON data
GET /api/v1/workflow_viz/workflow_json.json?tracker_id={tracker_id}
```

## Configuration

### Plugin Settings

Access plugin settings via **Administration** → **Plugins** → **Configure**:

- **Default Diagram Type**: Choose between flowchart and state diagram
- **Show Status Colors**: Enable/disable color coding for different status types
- **Enable Export**: Allow users to export diagrams
- **Mermaid Theme**: Select default theme for diagrams
- **Maximum Diagram Width**: Set maximum width for diagrams
- **Cache Diagrams**: Enable caching for better performance
- **Show Role Labels**: Display role names on transitions
- **Enable Fullscreen**: Allow fullscreen diagram viewing

### Permissions

The plugin adds the following permissions:

- **View workflow visualization**: Basic viewing permission
- **Manage workflow visualization**: Advanced management features

Assign these permissions to appropriate roles in **Administration** → **Roles and permissions**.

## Customization

### Adding Custom Themes

You can extend the plugin with custom Mermaid.js themes by modifying the helper:

```ruby
# In app/helpers/workflow_viz_helper.rb
def mermaid_theme_options
  [
    ['Default', 'default'],
    ['Dark', 'dark'],
    ['Forest', 'forest'],
    ['Neutral', 'neutral'],
    ['Custom', 'custom']  # Add your custom theme
  ]
end
```

### Custom Styling

Override the default styles by creating a custom CSS file:

```css
/* In your theme or custom CSS */
.workflow-diagram-main {
  border: 2px solid #your-color;
  border-radius: 10px;
}

.mermaid-container {
  background: #your-background;
}
```

## API Documentation

### Endpoints

#### GET /api/v1/workflow_viz.json
Returns list of available trackers and their workflow URLs.

**Response**:
```json
{
  "project": {
    "id": 1,
    "name": "Sample Project"
  },
  "trackers": [
    {
      "id": 1,
      "name": "Bug",
      "workflow_url": "/api/v1/workflow_viz/1.json"
    }
  ]
}
```

#### GET /api/v1/workflow_viz/{id}.json
Returns complete workflow data for a specific tracker.

**Response**:
```json
{
  "tracker": {
    "id": 1,
    "name": "Bug"
  },
  "workflow": {
    "statuses": [...],
    "transitions": [...]
  },
  "mermaid_diagram": "graph TD; ...",
  "generated_at": "2024-08-01T10:00:00Z"
}
```

#### GET /api/v1/workflow_viz/mermaid_data.json
Returns Mermaid diagram code for a specific tracker.

**Parameters**:
- `tracker_id` (required): Tracker ID
- `diagram_type` (optional): 'flowchart' or 'stateDiagram-v2'
- `theme` (optional): Mermaid theme name
- `show_roles` (optional): 'true' to show role labels

## Development

### Running Tests

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:test NAME=redmine_workflow_viz RAILS_ENV=test
```

### Code Structure

```
redmine_workflow_viz/
├── app/
│   ├── controllers/
│   │   ├── workflow_viz_controller.rb
│   │   ├── workflow_viz_admin_controller.rb
│   │   └── api/v1/workflow_viz_controller.rb
│   ├── helpers/
│   │   └── workflow_viz_helper.rb
│   └── views/
│       ├── workflow_viz/
│       ├── workflow_viz_admin/
│       └── settings/
├── assets/
│   └── stylesheets/
│       └── workflow_viz.css
├── config/
│   ├── locales/
│   │   ├── en.yml
│   │   └── ko.yml
│   └── routes.rb
├── test/
│   ├── functional/
│   └── unit/
├── init.rb
└── README.md
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Troubleshooting

### Common Issues

**Issue**: Diagrams not rendering
- **Solution**: Ensure JavaScript is enabled and Mermaid.js is loading properly

**Issue**: Empty workflow diagrams
- **Solution**: Check if workflows are properly configured for the tracker

**Issue**: Permission denied errors
- **Solution**: Verify user has appropriate permissions assigned

**Issue**: API returns 404 errors
- **Solution**: Check if the tracker ID exists and is accessible

### Debug Mode

Enable debug logging by adding to your Redmine configuration:

```ruby
# In config/additional_environment.rb
Rails.logger.level = Logger::DEBUG if Rails.env.development?
```

## License

This plugin is released under the MIT License. See LICENSE file for details.

## Support

- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: Check the wiki for additional documentation
- **Community**: Join the discussion in Redmine forums

## Changelog

### Version 1.0.0 (2024-08-01)
- Initial release
- Basic workflow visualization with Mermaid.js
- Project and admin interfaces
- RESTful API
- Export functionality
- Multi-language support
- Comprehensive test coverage

## Credits

- **Mermaid.js**: For the excellent diagramming library
- **Redmine Community**: For the robust plugin architecture
- **Contributors**: Thanks to all contributors and testers

---

For more information, visit the [project homepage](https://github.com/kether/redmine_workflow_viz).
