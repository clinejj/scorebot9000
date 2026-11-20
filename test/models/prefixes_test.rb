require "test_helper"

class PrefixesTest < ActiveSupport::TestCase
  EXPECTED = {
    "usr" => "User", "ser" => "Series", "evt" => "Event", "game" => "Game", "team" => "Team",
    "ptc" => "Participant", "scr" => "ScoreEntry", "adj" => "Adjustment", "snap" => "ResultSnapshot",
    "mbr" => "Membership", "hreq" => "HostRequest", "sms" => "SmsMessage", "apool" => "AliasPool"
  }.freeze

  test "every public model has its documented prefix" do
    Rails.application.eager_load!
    EXPECTED.each do |prefix, model|
      assert_equal prefix, model.constantize.id_prefix, "#{model} should use #{prefix}_"
      assert_equal model, PrefixedId.registry[prefix]
    end
  end

  test "internal tables have no prefix" do
    [ Session, SignInCode, Alias, AdminAuditEvent ].each { |model| assert_nil model.id_prefix }
  end

  test "every app table uses a uuid primary key" do
    Rails.application.eager_load!
    ApplicationRecord.descendants.reject(&:abstract_class?).each do |model|
      assert_equal :uuid, model.columns_hash[model.primary_key].type, "#{model.table_name}.id should be uuid"
    end
  end
end
