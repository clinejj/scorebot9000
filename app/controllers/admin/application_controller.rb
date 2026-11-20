# Parent for Scorebot's own admin pages (engines use Admin::BaseController
# directly so they keep their own layouts).
class Admin::ApplicationController < Admin::BaseController
  layout "admin"
end
