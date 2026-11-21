module Sms
  module Replies
    module_function

    def commands
      "Commands: REGISTER <team>, SCORE <game#> <score>, UNDO, WHO, GAMES, STANDINGS, CHANGE TEAM <name>, CHANGE NAME [name]. " \
        "In more than one event? Text JOIN <event code> first."
    end

    def which_event(command, known_sender: true)
      if command.name == :join
        "Couldn't find an event with code #{command.arg(:code) || "(missing)"}. Check the event page for its code."
      elsif known_sender
        "Which event? Text JOIN followed by the event code (it's on the event page)."
      else
        "You're not registered for an event yet. Text JOIN followed by the event code (it's on the event page) to sign up."
      end
    end

    def not_registered(event)
      hint = event.teams_self_registered? ? "REGISTER <team name>" : "REGISTER"
      "You're not registered for #{event.name} yet. Text #{hint} to join."
    end

    def unknown
      "Sorry, I didn't understand that. Text COMMANDS for the list."
    end
  end
end
