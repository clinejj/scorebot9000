# The controller-level half of the admin gate (AdminConstraint is the
# route-level half). Parent of every admin controller, including the
# Maintenance Tasks and Mission Control engines, which keep their own layouts.
class Admin::BaseController < ApplicationController
  before_action :require_platform_admin!
end
