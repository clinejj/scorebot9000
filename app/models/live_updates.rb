# Turbo refresh broadcasts for live pages. Turbo's suppression flag is per
# model class, so bulk work (legacy import, seeds) suppresses each
# broadcasting model explicitly.
module LiveUpdates
  BROADCASTING_MODELS = %w[Event ScoreEntry Adjustment].freeze

  def self.suppress(models = BROADCASTING_MODELS.map(&:constantize), &block)
    return yield if models.empty?

    models.first.suppressing_turbo_broadcasts { suppress(models.drop(1), &block) }
  end
end
