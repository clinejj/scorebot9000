module Legacy
  # Imports the legacy Datastore dump into the relational schema (plan
  # section 11.2). Each step is idempotent and reads only the dump and the
  # database, so steps can run in separate jobs and be re-run safely.
  class Importer
    STEPS = %w[events games aliases players scores dates texts settings snapshots].freeze

    SERIES_SLUG = "clinelympics".freeze
    SERIES_NAME = "Clinelympic Games".freeze
    SERIES_DOMAIN = "clinelympics.com".freeze
    SERIES_TAGLINE = "The annual contest of athletic skill and mental fortitude".freeze
    ALIAS_POOL_NAME = "Clinelympics Classics".freeze
    TIME_ZONE = "America/Los_Angeles".freeze

    attr_reader :report

    def initialize(dump, report: Report.new, captured: CapturedResults.load_all)
      @dump = dump
      @report = report
      @captured = captured
    end

    def run!
      STEPS.each { |step| run_step!(step) }
      report
    end

    def run_step!(step)
      raise ArgumentError, "unknown step #{step}" unless STEPS.include?(step)

      # Bulk imports shouldn't push thousands of page refreshes.
      LiveUpdates.suppress do
        ApplicationRecord.transaction { send("import_#{step}") }
      end
    end

    private
      # -- events ---------------------------------------------------------------

      def import_events
        rows = unique_rows(@dump[:event], "event") { |row| row["eventID"] }
        rows.each do |row|
          event = Event.find_or_initialize_by(legacy_event_id: row["eventID"].to_i)
          name = row["eventName"].to_s.squish.presence || "Legacy event #{row["eventID"]}"
          year = name[/\b(19|20)\d{2}\b/]
          event.assign_attributes(
            series: series, name: name, edition_label: year,
            status: truthy(row["archived"]) ? "archived" : "final",
            registration_open: false, time_zone: TIME_ZONE,
            team_mode: truthy(row["teams"]) ? "self_registered" : "none",
            alias_mode: "random", allow_alias_override: false,
            scoring: {
              "preset" => truthy(row["teamscore"]) ? "legacy_clinelympics" : "legacy_clinelympics_individual",
              "medals" => Scoring::Config.medals_from_names(row["medals"].presence || "Gold,Silver,Bronze")
            }
          )
          event.slug ||= year ? "clinelympics-#{year}" : nil
          event.sms_code ||= "CLINE#{year.to_s[-2..] || row["eventID"]}"
          event.save!
        end
        report.count(:events, source: @dump[:event].size, imported: Event.where.not(legacy_event_id: nil).count)
      end

      def series
        @series ||= Series.find_or_create_by!(slug: SERIES_SLUG) do |series|
          series.name = SERIES_NAME
          series.tagline = SERIES_TAGLINE
          series.custom_domain = SERIES_DOMAIN unless Series.exists?(custom_domain: SERIES_DOMAIN)
          series.theme = { "accent" => "#b91c1c" }
        end
      end

      # -- games ----------------------------------------------------------------

      def import_games
        rows = unique_rows(@dump[:game], "game") { |row| [ row["eventID"], row["gameID"] ] }
        imported = 0
        rows.each do |row|
          event = event_for(row["eventID"]) or next report.warn(:orphans, "game #{row["gameID"]} (#{row["gameName"]}) references missing event #{row["eventID"]}")
          game = event.games.find_or_initialize_by(position: row["gameID"].to_i)
          game.assign_attributes(
            name: row["gameName"].to_s.squish.presence || "Game #{row["gameID"]}",
            direction: truthy(row["scoreType"], default: true) ? "higher_better" : "lower_better",
            participation: "individual", team_aggregation: "sum", attempt_policy: "latest",
            score_format: "integer", status: "final", legacy_game_id: row["gameID"].to_i
          )
          game.save!
          imported += 1
        end
        report.count(:games, source: @dump[:game].size, imported: imported)
      end

      # -- aliases --------------------------------------------------------------

      def import_aliases
        pool = AliasPool.find_or_create_by!(name: ALIAS_POOL_NAME, owner: series)
        names = @dump[:name].map { |row| row["Name"].to_s.squish }.compact_blank
        pool.add_names(names.join("\n"))
        series.update!(default_alias_pool: pool) if series.default_alias_pool_id.nil?
        report.count(:names, source: @dump[:name].size, imported: pool.aliases.count)
        duplicates = names.size - names.map(&:downcase).uniq.size
        report.warn(:duplicates, "#{duplicates} duplicate alias names skipped") if duplicates.positive?
      end

      # -- players --------------------------------------------------------------

      def import_players
        rows = unique_rows(@dump[:player], "player") { |row| [ row["eventID"], row["playerID"].to_s.strip ] }
        imported = 0
        rows.each do |row|
          event = event_for(row["eventID"]) or next report.warn(:orphans, "player #{row["playerName"]} references missing event #{row["eventID"]}")
          user = user_for(row["playerID"])
          participant = event.participants.find_or_initialize_by(user: user)
          participant.alias_name = unique_alias(event, participant, row["playerName"].to_s.squish.presence || "Player")
          participant.alias_source = "import"
          participant.registered_via = "import"
          participant.team = team_for(event, row["teamName"])
          participant.save!
          imported += 1
        end
        report.count(:players, source: @dump[:player].size, imported: imported)
        report.count(:people, imported: Participant.joins(:event).where.not(events: { legacy_event_id: nil }).distinct.count(:user_id))
      end

      def user_for(player_id)
        raw = player_id.to_s.strip
        @users ||= {}
        @users[raw] ||= begin
          if (phone = PhoneNumber.normalize(raw))
            User.find_by(phone: phone) || User.create!(phone: phone)
          else
            report.warn(:invalid_phones, "player ID #{raw.inspect} isn't a phone number; imported as a placeholder user")
            User.find_by(legacy_player_id: raw) || User.create!(placeholder: true, legacy_player_id: raw)
          end
        end
      end

      def team_for(event, team_name)
        name = team_name.to_s.squish
        return nil if name.blank? || !event.uses_teams?

        display = name == name.upcase ? name.titleize : name
        event.teams.find_by_name(name) || event.teams.create!(name: display.first(60))
      end

      def unique_alias(event, participant, name)
        taken = event.participants.where.not(id: participant.id).pluck(Arel.sql("lower(alias_name)"))
        return name unless taken.include?(name.downcase)

        report.warn(:duplicates, "#{event.name}: two players were both \"#{name}\"; the second is now \"#{name} (2)\"")
        (2..).each { |n| candidate = "#{name} (#{n})"; return candidate unless taken.include?(candidate.downcase) }
      end

      # -- scores ---------------------------------------------------------------

      def import_scores
        latest = {}
        @dump[:score].each do |row|
          key = [ row["eventID"], row["playerID"].to_s.strip, row["gameID"] ]
          if latest[key]
            report.warn(:duplicates, "multiple scores for player #{mask(row["playerID"])} in event #{row["eventID"]} game #{row["gameID"]}; kept the latest")
            next if time(latest[key]["date"]) && time(row["date"]) && time(row["date"]) < time(latest[key]["date"])
          end
          latest[key] = row
        end

        imported = 0
        latest.each_value do |row|
          event = event_for(row["eventID"]) or next report.warn(:orphans, "score references missing event #{row["eventID"]}")
          game = event.games.find_by(position: row["gameID"].to_i) or next report.warn(:orphans, "#{event.name}: score for missing game #{row["gameID"]}")
          participant = event.participants.find_by(user: user_for(row["playerID"])) or
            next report.warn(:orphans, "#{event.name}: score from unregistered player #{mask(row["playerID"])} in #{game.name}")

          created_at = time(row["date"]) || event.starts_at || Time.utc(event.edition_label.to_i.nonzero? || 2012, 1, 15)
          entry = game.score_entries.active.find_by(participant: participant, source: "import")
          if entry
            entry.update!(value: row["playerScore"].to_i, raw_input: row["playerScore"].to_s)
          else
            ScoreEntry.create!(id: Uuid7.generate(time: created_at), game: game, participant: participant,
              value: row["playerScore"].to_i, raw_input: row["playerScore"].to_s, source: "import", created_at: created_at, updated_at: created_at)
          end
          imported += 1
        end
        report.count(:scores, source: @dump[:score].size, imported: imported)
      end

      # -- dates ----------------------------------------------------------------

      # The legacy app never stored event dates; derive them from score times.
      def import_dates
        Event.where.not(legacy_event_id: nil).find_each do |event|
          first, last = ScoreEntry.joins(:game).where(games: { event_id: event.id }).pick(Arel.sql("MIN(score_entries.created_at), MAX(score_entries.created_at)"))
          if first
            event.update!(starts_at: first, ends_at: last, finalized_at: last)
          else
            fallback = Time.find_zone(TIME_ZONE).local(event.edition_label.to_i.nonzero? || 2012, 1, 15, 15)
            event.update!(starts_at: event.starts_at || fallback, finalized_at: event.finalized_at || fallback)
            report.warn(:dates, "#{event.name} has no scores, so its date is a guess (#{fallback.to_date}); fix it in the organizer console")
          end
        end
      end

      # -- texts ----------------------------------------------------------------

      def import_texts
        events = Event.where.not(legacy_event_id: nil).where.not(starts_at: nil).to_a
        imported = 0
        @dump[:text].each do |row|
          sid = row["SmsSid"].to_s.strip.presence
          sent_at = time(row["date"]) || Time.current
          phone = PhoneNumber.normalize(row["From"])
          attributes = {
            direction: "inbound", body: row["Body"].to_s.first(1600), from_number: phone || row["From"].to_s.strip.presence,
            user: phone && User.find_by(phone: phone), event: event_at(events, sent_at), legacy: true, simulated: sid.nil?,
            status: "legacy", created_at: sent_at, updated_at: sent_at
          }
          message = sid ? SmsMessage.find_or_initialize_by(twilio_sid: sid) : SmsMessage.find_or_initialize_by(legacy: true, created_at: sent_at, body: attributes[:body])
          message.id ||= Uuid7.generate(time: sent_at)
          message.assign_attributes(attributes)
          message.save!
          imported += 1
        end
        report.count(:texts, source: @dump[:text].size, imported: imported)
      end

      def event_at(events, time)
        events.find { |event| time.between?(event.starts_at - 2.days, (event.ends_at || event.starts_at) + 1.day) }
      end

      # -- settings -------------------------------------------------------------

      def import_settings
        rows = @dump[:setting]
        report.warn(:duplicates, "#{rows.size} settings rows; used the first") if rows.size > 1
        row = rows.first or return
        report.data["legacy_site_name"] = row["siteName"]

        admin = User.platform_admins.order(:created_at).first
        unless admin
          report.warn(:settings, "No platform admin yet; grant one (bin/rails users:grant_admin) and re-run the import to attach the legacy admin phone")
          return
        end

        admin.update!(legacy_admin_nickname: row["adminName"].presence)
        phone = PhoneNumber.normalize(row["adminNumName"])
        return if phone.nil? || admin.phone == phone

        if (other = User.find_by(phone: phone)) && other != admin
          Users::Merge.call(keep: admin, duplicate: other)
          report.warn(:merges, "Merged the legacy admin phone's player history into #{admin.email || admin.public_id}")
        elsif admin.phone.nil?
          admin.update!(phone: phone)
        end
      rescue Users::Merge::Conflict => error
        report.warn(:merges, "Couldn't merge the legacy admin phone into the admin account: #{error.message}")
      end

      # -- snapshots ------------------------------------------------------------

      # Official results: the captured legacy pages where we have them (what
      # was shown and announced), otherwise computed with the legacy preset.
      def import_snapshots
        Event.where.not(legacy_event_id: nil).find_each do |event|
          computed = Scoring::Standings.compute(event)
          capture = @captured[event.legacy_event_id]
          event.result_snapshots.delete_all

          if capture
            announced = CapturedResults.new(capture, event).to_result
            store_snapshot(event, announced, "legacy_capture")
            diffs = CapturedResults.diff(announced, computed)
            report.event(event.legacy_event_id, name: event.name, snapshot: "legacy_capture", diffs: diffs)
          else
            store_snapshot(event, computed, "computed")
            report.event(event.legacy_event_id, name: event.name, snapshot: "computed", diffs: [])
            report.warn(:captures, "#{event.name}: no captured results; official results were recomputed with the legacy rules")
          end
        end
      end

      def store_snapshot(event, result, source)
        payload = Scoring::Serializer.dump(result)
        event.result_snapshots.create!(computed_at: result.computed_at, official: true, source: source,
          scoring_config: result.config.to_h, **ResultSnapshot.columns_from(payload))
      end

      # -- helpers --------------------------------------------------------------

      def event_for(legacy_id)
        @events ||= {}
        @events[legacy_id.to_i] ||= Event.find_by(legacy_event_id: legacy_id.to_i)
      end

      def unique_rows(rows, kind)
        seen = {}
        rows.each_with_object([]) do |row, unique|
          key = yield(row)
          if seen[key]
            report.warn(:duplicates, "duplicate #{kind} row #{key.inspect}; kept the first")
          else
            seen[key] = true
            unique << row
          end
        end
      end

      def truthy(value, default: false)
        return default if value.nil?

        value == true || value.to_s.downcase == "true"
      end

      def time(value)
        value.presence && Time.iso8601(value.to_s)
      rescue ArgumentError
        Time.zone.parse(value.to_s)
      end

      def mask(player_id)
        PhoneNumber.mask(PhoneNumber.normalize(player_id)) || player_id.to_s
      end
  end
end
