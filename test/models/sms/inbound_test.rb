require "test_helper"

module Sms
  class InboundTest < ActiveSupport::TestCase
    setup do
      Flipper.enable_actor(:sms_scoring, users(:organizer))
      @event = events(:clinelympics_2027)
    end

    def text(body, from: "+19095550111", sid: nil)
      Inbound.call(from: from, body: body, to: "+19097267311", sid: sid).reply
    end

    test "REGISTER joins the live event with a team and a random alias" do
      reply = text("REGISTER Night Owls", from: "+19095550115")
      assert_match(/\AWelcome to team Night Owls, .+!/, reply)
      assert_equal "Night Owls", @event.participant_for(users(:erin)).team.name
    end

    test "REGISTER from a brand new number creates the player" do
      assert_difference -> { User.count } do
        text("REGISTER Bears", from: "909-555-0188")
      end
      assert_equal "sms", User.find_by(phone: "+19095550188").participants.first.registered_via
    end

    test "texts from an unknown number don't create an account" do
      assert_no_difference -> { User.count } do
        assert_match "You're not registered for 2027 Clinelympic Games yet. Text REGISTER <team name> to join.", text("WHO", from: "+19095550188")
        assert_match "not registered", text("SCORE 1 5", from: "+19095550188")
        assert_match "didn't understand", text("ADMIN STOP", from: "+19095550188")
      end
      inbound = SmsMessage.inbound.where(from_number: "+19095550188").order(:created_at).first
      assert_nil inbound.user
      assert_equal @event, inbound.event
    end

    test "a failed registration from a new number leaves no account" do
      assert_no_difference [ "User.count", "Participant.count" ] do
        assert_match "Include a team name", text("REGISTER", from: "+19095550188")
        @event.update!(registration_open: false)
        assert_match "Registration is closed", text("REGISTER Bears", from: "+19095550188")
      end
    end

    test "an unknown number with no event to route to is pointed at JOIN" do
      Event.update_all(status: "final")
      assert_no_difference -> { User.count } do
        assert_match "You're not registered for an event yet. Text JOIN", text("SCORE 1 3", from: "+19095550188")
      end
    end

    test "JOIN with a team from a new number creates the player in that event" do
      assert_difference -> { User.count } do
        assert_match "Welcome to team Bears", text("JOIN CLINE27 Bears", from: "+19095550188")
      end
      assert_equal @event, User.find_by(phone: "+19095550188").sms_context_event
    end

    test "REGISTER again says you're already in" do
      assert_match "already in 2027 Clinelympic Games as Usain Bolt on team Wheaties", text("REGISTER Wheaties")
    end

    test "SCORE records a score and reports the place" do
      reply = text("SCORE 1 20")
      assert_equal "Got it: Trivia 20 for Usain Bolt. Wheaties is 1st in Trivia so far.", reply
      assert_equal 20, ScoreEntry.order(:created_at).last.value
    end

    test "SCORE for a team game records it for the team" do
      assert_match "for team Wheaties", text("SCORE 4 9")
    end

    test "SCORE explains mistakes" do
      assert_match "Send it like", text("SCORE")
      assert_match "no game 9", text("SCORE 9 1")
      assert_match "1:23.45", text("SCORE 3 fast")
      assert_match "not registered", text("SCORE 1 5", from: "+19095550115")
    end

    test "UNDO voids the last score" do
      text("SCORE 2 41")
      assert_equal "Removed your Mini Golf score (41).", text("UNDO")
    end

    test "WHO lists your alias, team and scores" do
      assert_equal "You're Usain Bolt on team Wheaties in 2027 Clinelympic Games. Scores: Trivia 12.", text("WHO")
    end

    test "GAMES lists numbers and notes" do
      reply = text("GAMES")
      assert_match "1 Trivia", reply
      assert_match "2 Mini Golf (low wins)", reply
      assert_match "3 Relay (low wins, time)", reply
      assert_match "4 Team Quiz (team)", reply
    end

    test "STANDINGS shows the top and your position" do
      assert_match(/\AStandings: 1 Bears \d+, 2 Wheaties \d+\. Wheaties is 2nd\.\z/, text("STANDINGS"))
    end

    test "CHANGE TEAM and CHANGE NAME" do
      assert_equal "You're now on team Bears.", text("CHANGE TEAM bears")
      assert_equal "Your new name is Flo Jo.", text("CHANGE NAME Flo Jo")
      assert_match "Your new name is", text("CHANGE NAME")
    end

    test "COMMANDS works even without an event" do
      Event.update_all(status: "final")
      assert_match "REGISTER <team>", text("COMMANDS")
    end

    test "carrier keywords get no reply" do
      assert_nil text("STOP")
      assert_nil text("HELP")
    end

    test "unknown commands get help" do
      assert_match "COMMANDS", text("dance")
    end

    test "events without SMS enabled say so" do
      Flipper.disable_actor(:sms_scoring, users(:organizer))
      assert_match "Texting isn't turned on", text("SCORE 1 5")
    end

    test "ambiguous routing asks for JOIN, and JOIN picks the event" do
      other = Event.create!(name: "Lake Day", status: "live", registration_open: true, team_mode: "none", sms_code: "LAKE27")
      Membership.create!(user: users(:organizer), resource: other, role: "owner")
      assert_match "Which event?", text("REGISTER", from: "+19095550115")
      assert_match "registered as", text("JOIN LAKE27", from: "+19095550115")
      assert_equal other, users(:erin).reload.sms_context_event
      assert_match "Couldn't find an event with code NOPE", text("JOIN NOPE", from: "+19095550115")
    end

    test "registered players route to their event even when several are live" do
      other = Event.create!(name: "Lake Day", status: "live", registration_open: true, team_mode: "none", sms_code: "LAKE27")
      Membership.create!(user: users(:organizer), resource: other, role: "owner")
      assert_match "Trivia", text("SCORE 1 3")
    end

    test "ADMIN commands require an organizer role" do
      assert_match "didn't understand", text("ADMIN STOP")
      users(:organizer).update!(phone: "+19095550190")
      assert_match "paused", text("ADMIN STOP", from: "+19095550190")
      assert @event.reload.published?
      assert_match "is live", text("ADMIN START CLINE27", from: "+19095550190")
      assert_match "locked", text("ADMIN LOCK 1", from: "+19095550190")
      assert games(:trivia).reload.locked?
      assert_match "isn't accepting scores", text("SCORE 1 3")
      assert_match "is final. Congratulations, Bears!", text("ADMIN FINAL", from: "+19095550190")
    end

    test "logs inbound messages and replies" do
      text("WHO", sid: "SM123")
      inbound = SmsMessage.find_by!(twilio_sid: "SM123")
      assert_equal "who", inbound.command
      assert_equal users(:alice), inbound.user
      assert_equal @event, inbound.event
      assert_match "Usain Bolt", inbound.reply.body
    end

    test "Twilio retries return the original reply without reprocessing" do
      first = text("SCORE 2 40", sid: "SM777")
      assert_no_difference -> { ScoreEntry.count } do
        assert_equal first, text("SCORE 2 40", sid: "SM777")
      end
    end

    test "the pause switch logs but doesn't process" do
      Flipper.enable(:pause_sms_inbound)
      assert_nil text("SCORE 1 99", sid: "SM999")
      assert_equal "paused", SmsMessage.find_by!(twilio_sid: "SM999").status
    end

    test "rate limits a number that floods us" do
      (Inbound::SENDER_LIMIT + 1).times { |i| SmsMessage.create!(direction: "inbound", from_number: "+19095550111", body: "x#{i}") }
      assert_nil text("WHO", sid: "SMflood")
      assert_equal "rate_limited", SmsMessage.find_by!(twilio_sid: "SMflood").status
    end

    test "stops replying for the day once the platform hits its daily reply cap" do
      ENV["SMS_DAILY_REPLY_CAP"] = "2"
      other = Event.create!(name: "Lake Day", status: "live")
      SmsMessage.create!(direction: "outbound", event: other, body: "a reply for another event")
      SmsMessage.create!(direction: "outbound", event: @event, body: "a simulated reply", simulated: true)
      assert_match "Usain Bolt", text("WHO")
      assert_nil text("WHO", sid: "SMcap")
      assert_equal "capped", SmsMessage.find_by!(twilio_sid: "SMcap").status

      travel_to Time.current.in_time_zone("America/Los_Angeles").tomorrow.beginning_of_day + 1.minute do
        assert_match "Usain Bolt", text("WHO")
      end
    ensure
      ENV.delete("SMS_DAILY_REPLY_CAP")
    end
  end
end
