# Active Storage and Action Text tables also use uuid primary keys (they were
# installed after setting primary_key_type: :uuid). Give them UUIDv7s too.
ActiveSupport.on_load(:active_storage_record) { include MintsUuidV7 }
ActiveSupport.on_load(:action_text_record) { include MintsUuidV7 }
