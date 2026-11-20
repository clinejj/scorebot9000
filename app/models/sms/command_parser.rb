module Sms
  Command = Data.define(:name, :args, :raw) do
    def arg(key) = args[key]
  end

  # Parses an inbound text into a Command. Case-insensitive and tolerant of
  # extra whitespace; never raises (unknown input becomes :unknown).
  #
  #   REGISTER [team]         JOIN <code> [team]      SCORE <game#> <value>
  #   UNDO   WHO   GAMES   STANDINGS   COMMANDS
  #   CHANGE TEAM <name>      CHANGE NAME [name]
  #   ADMIN START [code] | STOP | FINAL | LOCK <game#> | UNLOCK <game#>
  class CommandParser
    ALIASES = {
      "S" => "SCORE", "R" => "REGISTER", "REG" => "REGISTER", "?" => "COMMANDS", "COMMAND" => "COMMANDS",
      "ME" => "WHO", "RANK" => "STANDINGS", "STANDING" => "STANDINGS", "LEADERBOARD" => "STANDINGS",
      "LIST" => "GAMES", "GAME" => "GAMES", "TEAM" => "CHANGE_TEAM", "NAME" => "CHANGE_NAME"
    }.freeze

    # Carrier/Twilio keywords, matched against the whole message. Twilio
    # handles these (opt-out, opt-in, and HELP via Advanced Opt-Out), so we
    # log them and stay quiet to avoid double replies.
    CARRIER_KEYWORDS = %w[STOP STOPALL UNSUBSCRIBE CANCEL END QUIT START YES UNSTOP HELP INFO].freeze

    def self.parse(body)
      text = body.to_s.unicode_normalize(:nfkc).squish
      return Command.new(name: :empty, args: {}, raw: text) if text.empty?
      return Command.new(name: :carrier_keyword, args: {}, raw: text) if CARRIER_KEYWORDS.include?(text.upcase)

      word, rest = text.split(" ", 2)
      keyword = word.upcase
      keyword = ALIASES.fetch(keyword, keyword)
      rest = rest.to_s.strip

      name, args =
        case keyword
        when "REGISTER" then [ :register, { team: rest.presence } ]
        when "JOIN"
          code, team = rest.split(" ", 2)
          [ :join, { code: code&.upcase, team: team&.strip.presence } ]
        when "SCORE"
          game, value = rest.split(" ", 2)
          [ :score, { game: game, value: value&.strip } ]
        when "UNDO" then [ :undo, {} ]
        when "WHO" then [ :who, {} ]
        when "GAMES" then [ :games, {} ]
        when "STANDINGS" then [ :standings, {} ]
        when "COMMANDS" then [ :commands, {} ]
        when "CHANGE" then parse_change(rest)
        when "CHANGE_TEAM" then [ :change_team, { team: rest.presence } ]
        when "CHANGE_NAME" then [ :change_name, { alias_name: rest.presence } ]
        when "ADMIN" then parse_admin(rest)
        else [ :unknown, {} ]
        end
      Command.new(name: name, args: args, raw: text)
    end

    def self.parse_change(rest)
      sub, value = rest.split(" ", 2)
      case sub&.upcase
      when "TEAM" then [ :change_team, { team: value&.strip.presence } ]
      when "NAME" then [ :change_name, { alias_name: value&.strip.presence } ]
      else [ :unknown, {} ]
      end
    end

    def self.parse_admin(rest)
      sub, value = rest.split(" ", 2)
      action = sub&.upcase
      if %w[START STOP FINAL LOCK UNLOCK].include?(action)
        [ :admin, { action: action.downcase.to_sym, value: value&.strip.presence } ]
      else
        [ :unknown, {} ]
      end
    end
  end
end
