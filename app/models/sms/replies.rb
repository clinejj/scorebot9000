module Sms
  module Replies
    module_function

    def commands
      "Commands: REGISTER <team>, SCORE <game#> <score>, UNDO, WHO, GAMES, STANDINGS, CHANGE TEAM <name>, CHANGE NAME [name]. " \
        "In more than one event? Text JOIN <event code> first."
    end

    def which_event(command)
      if command.name == :join
        "Couldn't find an event with code #{command.arg(:code) || "(missing)"}. Check the event page for its code."
      else
        "Which event? Text JOIN followed by the event code (it's on the event page)."
      end
    end

    def unknown
      "Sorry, I didn't understand that. Text COMMANDS for the list."
    end
  end
end
