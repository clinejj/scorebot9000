# Flipper gates, kill switches and rollouts (plan section 7.5). Per-record
# permissions (organizer of event X) live in memberships, not here.
Rails.application.configure do
  # Preload all features once per request; there are only a handful.
  config.flipper.preload = true
end

Flipper.register(:platform_admins) do |actor|
  actor.respond_to?(:platform_admin?) && actor.platform_admin?
end

Flipper::UI.configure do |config|
  config.application_breadcrumb_href = "/admin"
  config.banner_text = "Scorebot 9000 · changes take effect immediately and are audited"
  config.banner_class = "warning"
  config.fun = false
  config.descriptions_source = ->(_keys) { FeatureFlags::DESCRIPTIONS }
  config.show_feature_description_in_list = true
end

# Audit every flag change (who, which flag, which gate/actor).
ActiveSupport::Notifications.subscribe("feature_operation.flipper") do |*, payload|
  next unless FeatureFlags::AUDITED_OPERATIONS.include?(payload[:operation])

  thing = payload[:thing]
  AdminAuditEvent.record!(
    "flipper.#{payload[:operation]}",
    subject: payload[:feature_name],
    gate: payload[:gate_name]&.to_s,
    value: thing.respond_to?(:value) ? thing.value.to_s : thing.to_s.presence
  )
rescue ActiveRecord::ActiveRecordError => error
  Rails.logger.error("Flipper audit failed: #{error.message}")
end
