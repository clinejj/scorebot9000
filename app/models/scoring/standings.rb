module Scoring
  # Standings for an event: the official snapshot once an event is finished,
  # otherwise computed live (cached until any game, team, participant, score
  # or adjustment changes, since those all touch the event).
  module Standings
    module_function

    def for(event)
      if event.finished? && (snapshot = event.official_snapshot)
        Serializer.load(snapshot.standings_payload)
      else
        compute_cached(event)
      end
    end

    def compute(event)
      Engine.new(event.scoring_config).call(**EventData.load(event))
    end

    def compute_cached(event)
      payload = Rails.cache.fetch([ "standings/v1", event.cache_key_with_version, event.scoring_config.digest ], expires_in: 1.day) do
        Serializer.dump(compute(event))
      end
      Serializer.load(payload)
    end
  end
end
