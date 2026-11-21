require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home renders" do
    get root_path
    assert_response :success
  end

  test "privacy policy includes the no-sharing language 10DLC reviewers look for" do
    get privacy_path
    assert_response :success
    assert_match "No mobile information will be shared with third parties or affiliates for marketing or promotional purposes", response.body
  end

  test "sms terms describe opt-in, frequency, rates, HELP and STOP" do
    get sms_terms_path
    assert_response :success
    %w[REGISTER HELP STOP].each { |word| assert_match word, response.body }
    assert_match "Message and data rates may apply", response.body
  end

  test "health check" do
    get rails_health_check_path
    assert_response :success
  end
end
