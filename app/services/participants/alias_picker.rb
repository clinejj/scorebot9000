module Participants
  # Picks a random unused alias for an event from its alias pool (event pool,
  # else the series default, else the platform default). Falls back to a
  # generated "Turbo Otter"-style name when the pool is empty or exhausted.
  class AliasPicker
    ADJECTIVES = %w[Turbo Mighty Sneaky Golden Cosmic Electric Fearless Lucky Swift Jolly Atomic Velvet
      Thunder Crimson Midnight Rogue Stellar Feral Noble Spicy Sonic Frosty Blazing Wily].freeze
    NOUNS = %w[Otter Falcon Badger Comet Panda Yeti Narwhal Mongoose Phoenix Walrus Gecko Moose
      Tiger Kraken Raccoon Llama Bison Viper Heron Jaguar Lemur Puffin Wombat Dragon].freeze

    def initialize(event)
      @event = event
    end

    def pick
      from_pool || generated
    end

    private
      attr_reader :event

      def taken
        @taken ||= event.participants.pluck(Arel.sql("lower(alias_name)"))
      end

      def from_pool
        pool = event.effective_alias_pool or return nil
        scope = pool.aliases
        scope = scope.where.not("lower(name) IN (?)", taken) if taken.any?
        scope.order(Arel.sql("random()")).pick(:name)
      end

      def generated
        50.times do
          candidate = "#{ADJECTIVES.sample} #{NOUNS.sample}"
          return candidate unless taken.include?(candidate.downcase)
        end
        "Player #{SecureRandom.alphanumeric(4).upcase}"
      end
  end
end
