require "test_helper"

module Legacy
  class ImporterTest < ActiveSupport::TestCase
    CAPTURED = Rails.root.join("test/fixtures/files/legacy/captured")

    def dump
      Dump.parse(file_fixture("legacy/dump.jsonl").read)
    end

    def run_import(captured_dir: CAPTURED)
      Importer.new(dump, captured: CapturedResults.load_all(captured_dir)).run!
    end

    def event(legacy_id) = Event.find_by!(legacy_event_id: legacy_id)

    test "imports events into the Clinelympics series" do
      report = run_import
      first = event(1)
      assert_equal series(:clinelympics), first.series
      assert_equal "2012 Clinelympic Games", first.name
      assert_equal "clinelympics-2012", first.slug
      assert_equal "2012", first.edition_label
      assert first.final?
      assert_equal "legacy_clinelympics", first.scoring["preset"]
      assert_equal %w[Gold Silver Bronze], first.scoring_config.medal_names
      assert_includes report.warnings(:duplicates), "duplicate event row 2; kept the first"
      assert_equal "2013 Clinelympic Games", event(2).name
    end

    test "imports games with direction and position" do
      run_import
      trivia, golf = event(1).games.to_a
      assert_equal [ 1, "Trivia", "higher_better" ], [ trivia.position, trivia.name, trivia.direction ]
      assert_equal [ 2, "Golf", "lower_better" ], [ golf.position, golf.name, golf.direction ]
    end

    test "dedupes people across years by phone and keeps aliases unique per event" do
      report = run_import
      person = User.find_by!(phone: "+19095550201")
      assert_equal [ "Pele", "Usain Bolt" ], person.participants.map(&:alias_name).sort
      assert_equal [ "Mia Hamm", "Mia Hamm (2)" ], event(1).participants.where("alias_name LIKE 'Mia%'").pluck(:alias_name).sort
      assert_equal %w[Bears Wheaties], event(1).teams.map(&:name)
      assert report.warnings(:duplicates).any? { |warning| warning.include?("Mia Hamm (2)") }
    end

    test "imports invalid player IDs as placeholder users" do
      report = run_import
      placeholder = User.find_by!(legacy_player_id: "TESTER")
      assert placeholder.placeholder?
      assert_equal "Test Player", placeholder.participants.first.alias_name
      assert report.warnings(:invalid_phones).any? { |warning| warning.include?("TESTER") }
    end

    test "imports the latest score per player and game and reports orphans" do
      report = run_import
      trivia = event(1).games.find_by!(position: 1)
      usain = event(1).participants.find_by!(alias_name: "Usain Bolt")
      assert_equal [ 6 ], trivia.score_entries.active.where(participant: usain).pluck(:value).map(&:to_i)
      assert_equal Time.utc(2012, 1, 7, 23, 10), trivia.score_entries.where(participant: usain).first.created_at
      assert_equal 8, report.to_h.dig("counts", "scores", "imported")
      assert_equal 2, report.warnings(:orphans).count { |warning| warning.include?("score") }
      assert report.warnings(:orphans).any? { |warning| warning.include?("Orphan Game") }
    end

    test "derives event dates from score times" do
      run_import
      assert_equal Time.utc(2012, 1, 7, 23, 10), event(1).starts_at
      assert_equal Time.utc(2012, 1, 8, 0, 20), event(1).ends_at
    end

    test "imports aliases into the series pool" do
      run_import
      pool = AliasPool.find_by!(name: Importer::ALIAS_POOL_NAME)
      assert_equal series(:clinelympics).reload.default_alias_pool, pool
      assert_equal 1, pool.aliases.where("lower(name) = ?", "usain bolt").count
      assert pool.aliases.exists?(name: "Pele")
    end

    test "imports texts linked to users and events" do
      run_import
      real = SmsMessage.find_by!(twilio_sid: "SM0001")
      assert real.legacy?
      assert_not real.simulated?
      assert_equal User.find_by(phone: "+19095550201"), real.user
      assert_equal event(1), real.event
      simulated = SmsMessage.find_by!(body: "SCORE 1 4")
      assert simulated.simulated?
      assert_equal "+19095550202", simulated.from_number
    end

    test "attaches the legacy admin phone to the platform admin, merging their player history" do
      report = run_import
      admin = users(:admin).reload
      assert_equal "+19095550199", admin.phone
      assert_equal "oldadmin", admin.legacy_admin_nickname
      assert_equal [ "Ali" ], admin.participants.map(&:alias_name)
      assert_equal "Clinelympics", report.to_h["legacy_site_name"]
      assert report.warnings(:merges).any?
    end

    test "official results come from the captured pages when available" do
      report = run_import
      snapshot = event(1).official_snapshot
      assert snapshot.from_legacy_capture?
      result = event(1).standings
      assert_equal %w[Wheaties Bears], result.standings.map { |row| row.competitor.name }
      assert_equal [ 6, 5 ], result.standings.map { |row| row.total.to_i }
      assert result.standings.first.competitor.public_id.start_with?("team_")
      assert_equal [], report.to_h.dig("events", "1", "diffs")

      assert event(2).official_snapshot.from_computed?
      assert report.warnings(:captures).any? { |warning| warning.include?("2013") }
    end

    test "reports differences between announced and recomputed results" do
      report = run_import(captured_dir: Rails.root.join("test/fixtures/files/legacy/captured_mismatch"))
      diffs = report.to_h.dig("events", "1", "diffs")
      assert diffs.any? { |diff| diff.include?("Trivia / Bears: 12 shown, 10 recomputed") }
      # Display still follows the announced results.
      trivia = event(1).standings.game_results.find { |game| game.game.name == "Trivia" }
      assert_equal "Bears", trivia.rows.first.competitor.name
      assert_equal 0, trivia.rows.first.medal
    end

    test "is idempotent" do
      run_import
      counts = -> { [ Event.count, Game.count, Team.count, Participant.count, User.count, ScoreEntry.count, SmsMessage.count, ResultSnapshot.count, Alias.count ] }
      before = counts.call
      run_import
      assert_equal before, counts.call
    end
  end
end
