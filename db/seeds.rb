# Demo data for local development (bin/rails db:seed). Idempotent-ish: it
# skips everything if the demo series already exists.
return if Series.exists?(slug: "clinelympics")

LiveUpdates.suppress do
srand(2027)

platform_pool = AliasPool.find_or_create_by!(name: AliasPool::PLATFORM_DEFAULT_NAME, owner: nil)
platform_pool.add_names(<<~NAMES)
  Captain Scoreboard
  The Underdog
  Dark Horse
  Comeback Kid
  Photo Finish
  Sudden Death
  Hat Trick
  Golden Boot
NAMES

organizer = User.find_or_create_by!(email: "organizer@example.com") { |user| user.name = "Olive Organizer" }
admin = User.find_or_create_by!(email: "admin@example.com") { |user| user.platform_admin = true }
FeatureFlags.define_all!
Flipper.enable_group(:hosting, :platform_admins)
Flipper.enable_group(:sms_scoring, :platform_admins)
Flipper.enable_actor(:sms_scoring, organizer)

series = Series.create!(slug: "clinelympics", name: "Clinelympic Games", custom_domain: "clinelympics.com",
  tagline: "The annual contest of athletic skill and mental fortitude", theme: { "accent" => "#b91c1c" })
series.update!(description: "<p>Started in 2012 to celebrate a 25th birthday, the Clinelympic Games have become the defining event of our time.</p>")
pool = AliasPool.create!(name: "Clinelympics Classics", owner: series)
pool.add_names(%w[Usain\ Bolt Serena\ Williams Simone\ Biles Michael\ Phelps Mia\ Hamm Pele Florence\ Griffith\ Joyner
  Jackie\ Joyner-Kersee Carl\ Lewis Nadia\ Comaneci Jesse\ Owens Wilma\ Rudolph Greg\ Louganis Bonnie\ Blair
  Eric\ Heiden Kerri\ Strug Mark\ Spitz Katie\ Ledecky Shaun\ White Lindsey\ Vonn].join("\n"))
series.update!(default_alias_pool: pool)
Membership.create!(user: organizer, resource: series, role: "owner")

players = 12.times.map { |i| User.create!(phone: format("+1909555%04d", 1000 + i), name: "Player #{i + 1}") }
team_names = %w[Wheaties Bears Night\ Owls Comets]
games_spec = [
  [ "Trivia", "higher_better", "integer" ], [ "Contemporary Art", "higher_better", "integer" ],
  [ "Mini Golf", "lower_better", "integer" ], [ "Relay", "lower_better", "time" ], [ "Quiplash", "higher_better", "integer" ]
]

build_event = lambda do |year, status|
  event = series.events.create!(name: "#{year} Clinelympic Games", edition_label: year.to_s, slug: "clinelympics-#{year}",
    status: "live", registration_open: true, team_mode: "self_registered", max_team_size: 3,
    starts_at: Time.find_zone("America/Los_Angeles").local(year, 1, 9, 15), location_text: "The backyard",
    scoring: { "preset" => "weighted_medals" }, created_by_user: organizer)
  event.update!(description: "<p>The annual contest of athletic skill and mental fortitude. Opening ceremonies at 3pm, closing ceremonies at 5pm with a social hour to follow.</p>",
    rules: "<ul><li>Teams of 2 (or 3 if there's an odd number of people)</li><li>Team uniforms are not required, but highly encouraged</li><li>For team games, one player per team submits the team's score</li></ul>")
  games_spec.each { |name, direction, format| event.games.create!(name: name, direction: direction, score_format: format) }
  players.each_with_index do |user, index|
    Participants::Register.call(event: event, user: user, team_name: team_names[index % team_names.size], via: :sms)
  end
  played = status == "live" ? event.games.first(3) : event.games
  played.each do |game|
    event.participants.each do |participant|
      value = case game.score_format
      when "time" then format("%d:%02d.%d", 1, rand(5..55), rand(0..9))
      else game.lower_better? ? rand(30..60) : rand(0..25)
      end
      Scores::Submit.call(game: game, competitor: participant, raw_value: value, source: :sms, submitted_by: participant.user)
    end
  end
  Results::Finalize.call(event) if status == "final"
  event.update!(status: status) unless status == "final"
  event
end

build_event.call(2026, "final")
build_event.call(2027, "live")

backyard = Event.create!(name: "Backyard Olympics", edition_label: "2027", status: "published", registration_open: true,
  team_mode: "none", starts_at: 3.weeks.from_now.change(hour: 14), location_text: "Dolores Park", created_by_user: admin)
Membership.create!(user: admin, resource: backyard, role: "owner")
%w[Cornhole Frisbee\ Golf Water\ Balloon\ Toss].each { |name| backyard.games.create!(name: name) }

puts "Seeded demo data. Sign in as admin@example.com or organizer@example.com (codes print in development)."
end
