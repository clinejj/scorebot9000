# Fail fast at boot in production when a required secret is missing, instead
# of silently falling back to the dev-only defaults in config/application.rb.
if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  %w[
    SECRET_KEY_BASE
    DATABASE_URL
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
  ].each do |name|
    raise "Missing required environment variable #{name}" if ENV[name].blank?
  end
end
