module Scoring
  # Standings under proposed scoring settings, for the console's event
  # setup: the event's own scores once it has some, otherwise a sample event.
  module Preview
    Outcome = Data.define(:result, :config, :sample_source) do
      def sample? = !sample_source.nil?
    end

    module_function

    def call(config, event: nil)
      return Outcome.new(result: nil, config: config, sample_source: nil) unless config.valid?

      if event&.persisted? && ScoreEntry.active.joins(:game).where(games: { event_id: event.id }).exists?
        Outcome.new(result: Engine.new(config).call(**EventData.load(event)), config: config, sample_source: nil)
      else
        sample = SampleData.load
        Outcome.new(result: Engine.new(config).call(**sample.inputs), config: config, sample_source: sample.source)
      end
    end
  end
end
