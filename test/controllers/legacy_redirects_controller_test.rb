require "test_helper"

class LegacyRedirectsControllerTest < ActionDispatch::IntegrationTest
  setup { host! "clinelympics.com" }

  test "summary, medals and scores redirect to the legacy event's results" do
    %w[summary medals scores].each do |page|
      get "/#{page}.jsp", params: { e: 10 }
      assert_redirected_to results_event_path(events(:clinelympics_2021))
      assert_response :moved_permanently
    end
  end

  test "pages without an event go to the latest edition" do
    get "/summary.jsp"
    assert_redirected_to results_event_path(events(:clinelympics_2027))
    get "/details.jsp"
    assert_redirected_to event_path(events(:clinelympics_2027))
  end

  test "index and admin go home" do
    get "/index.jsp"
    assert_redirected_to "/"
    get "/admin.jsp"
    assert_redirected_to "/"
  end

  test "unknown legacy event ids fall back to home" do
    get "/summary.jsp", params: { e: 99 }
    assert_redirected_to "/"
  end
end
