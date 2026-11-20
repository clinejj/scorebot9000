require "test_helper"

class ScoreValueTest < ActiveSupport::TestCase
  test "parses integers" do
    assert_equal 228, ScoreValue.parse("228", :integer)
    assert_equal 1500, ScoreValue.parse("1,500", :integer)
    assert_equal(-3, ScoreValue.parse("-3", :integer))
    assert_nil ScoreValue.parse("12.5", :integer)
    assert_nil ScoreValue.parse("abc", :integer)
    assert_nil ScoreValue.parse("", :integer)
  end

  test "parses decimals to 3 places" do
    assert_equal BigDecimal("12.5"), ScoreValue.parse("12.5", :decimal)
    assert_equal BigDecimal("0.125"), ScoreValue.parse(".1249", :decimal)
    assert_nil ScoreValue.parse("1.2.3", :decimal)
  end

  test "parses times into seconds" do
    assert_equal BigDecimal("83.45"), ScoreValue.parse("1:23.45", :time)
    assert_equal BigDecimal("83.45"), ScoreValue.parse("83.45", :time)
    assert_equal BigDecimal("3723"), ScoreValue.parse("1:02:03", :time)
    assert_nil ScoreValue.parse("1:75", :time)
    assert_nil ScoreValue.parse("1:60:00", :time)
    assert_nil ScoreValue.parse("fast", :time)
  end

  test "parses placements" do
    assert_equal 1, ScoreValue.parse("1", :placement)
    assert_equal 3, ScoreValue.parse("3rd", :placement)
    assert_nil ScoreValue.parse("0", :placement)
    assert_nil ScoreValue.parse("1.5", :placement)
  end

  test "formats by score format" do
    assert_equal "228", ScoreValue.format(BigDecimal("228"), :integer)
    assert_equal "12.5", ScoreValue.format(BigDecimal("12.500"), :decimal)
    assert_equal "1:23.45", ScoreValue.format(BigDecimal("83.45"), :time)
    assert_equal "1:05", ScoreValue.format(BigDecimal("65"), :time)
    assert_equal "1:02:03", ScoreValue.format(BigDecimal("3723"), :time)
    assert_equal "9.5", ScoreValue.format(BigDecimal("9.5"), :time)
    assert_equal "2nd", ScoreValue.format(BigDecimal("2"), :placement)
  end

  test "rejects values outside the column range" do
    assert_nil ScoreValue.parse("999999999999999", :integer)
  end
end
