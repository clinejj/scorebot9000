# Every admin tool sits behind the platform-admin gate (plan section 7.4):
#   1. AdminConstraint wraps their routes (config/routes.rb), and
#   2. their controllers inherit Admin::BaseController (require_platform_admin!),
#      except Flipper UI (a plain Rack app; route constraint only) and Blazer
#      (before_action_method in config/blazer.yml).

# Maintenance Tasks
MaintenanceTasks.parent_controller = "Admin::BaseController"
MaintenanceTasks.metadata = -> { { user_id: current_user&.public_id, user_email: current_user&.email } }

# Mission Control - Jobs is configured in config/application.rb, because its
# engine reads the settings before app initializers run.
