require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scorebot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "UTC"

    # Every app table uses a UUID primary key holding a UUIDv7 minted in Ruby
    # (see ApplicationRecord). This must be configured before Active Storage,
    # Action Text or the auth generator are installed so their polymorphic
    # record_id / user_id columns are generated as uuid too.
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.system_tests = nil
    end

    # Mission Control - Jobs sits behind the platform-admin gate instead of
    # its own HTTP basic auth (see config/initializers/admin_tools.rb).
    config.mission_control.jobs.base_controller_class = "Admin::BaseController"
    config.mission_control.jobs.http_basic_auth_enabled = false

    # Secrets come from the environment (Fly secrets in production) rather
    # than encrypted credentials, so nothing depends on a master key that
    # only one machine holds. Dev/test use fixed, non-secret keys.
    config.active_record.encryption.primary_key =
      ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY") { "dev-only-primary-key-0123456789abcdef" }
    config.active_record.encryption.deterministic_key =
      ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY") { "dev-only-deterministic-key-0123456789" }
    config.active_record.encryption.key_derivation_salt =
      ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT") { "dev-only-key-derivation-salt-0123456789" }
  end
end
