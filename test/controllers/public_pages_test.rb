require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  test "platform home lists live events" do
    get root_path
    assert_response :success
    assert_select "#live", text: /2027 Clinelympic Games/
    assert_no_match "Backyard Games", response.body # drafts stay hidden
  end

  test "series page by slug shows editions and stats" do
    get series_path(series(:clinelympics))
    assert_response :success
    assert_select "h1", "Clinelympic Games"
    assert_match "2027 Clinelympic Games", response.body
    assert_match "--brand-accent: #b91c1c", response.body
  end

  test "a series custom domain roots at its series page" do
    host! "clinelympics.com"
    get "/"
    assert_response :success
    assert_select "h1", "Clinelympic Games"
    host! "www.clinelympics.com"
    get "/"
    assert_select "h1", "Clinelympic Games"
  end

  test "event home shows games, standings and SMS instructions when enabled" do
    Flipper.enable_actor(:sms_scoring, users(:organizer))
    with_sms_number("909-SCORE-11") do
      get event_path(events(:clinelympics_2027))
    end
    assert_response :success
    assert_select "h1", "2027 Clinelympic Games"
    assert_match "Mini Golf", response.body
    assert_match "Play by text", response.body
    assert_match "JOIN CLINE27", response.body
  end

  test "event home hides SMS instructions unless the host has SMS" do
    with_sms_number("909-SCORE-11") { get event_path(events(:clinelympics_2027)) }
    assert_no_match "Play by text", response.body
  end

  test "results show standings, both views and per-game medals" do
    get results_event_path(events(:clinelympics_2027))
    assert_response :success
    assert_select "table.table-scores"
    assert_match "Bears", response.body
    get results_event_path(events(:clinelympics_2027), view: "players")
    assert_response :success
    assert_match "Simone Biles", response.body
  end

  test "game page ranks scores with stats" do
    get event_game_path(events(:clinelympics_2027), games(:trivia))
    assert_response :success
    assert_select "td", "15"
    assert_match "Average", response.body
  end

  test "team page lists members" do
    get event_team_path(events(:clinelympics_2027), teams(:wheaties))
    assert_response :success
    assert_match "Usain Bolt", response.body
    assert_match "Serena Williams", response.body
  end

  test "team pages don't leak across events" do
    get event_team_path(events(:clinelympics_2021), teams(:wheaties))
    assert_response :not_found
  end

  test "tv mode renders" do
    get tv_event_path(events(:clinelympics_2027))
    assert_response :success
    assert_match "auto-refresh", response.body
  end

  test "draft events are hidden from the public but visible to their organizers" do
    get event_path(events(:draft_party))
    assert_response :not_found
    Membership.create!(user: users(:player), resource: events(:draft_party), role: "organizer")
    sign_in_as users(:player)
    get event_path(events(:draft_party))
    assert_response :success
  end

  test "pages never show phone numbers" do
    [ event_path(events(:clinelympics_2027)), results_event_path(events(:clinelympics_2027)), results_event_path(events(:clinelympics_2027), view: "players") ].each do |path|
      get path
      assert_no_match(/\+1909555/, response.body)
      assert_no_match(/909.?555.?01/, response.body)
    end
  end

  private
    def with_sms_number(number)
      original = Rails.configuration.x.sms_number
      Rails.configuration.x.sms_number = number
      yield
    ensure
      Rails.configuration.x.sms_number = original
    end
end
