defmodule FeedConsumer.ValidatorTest do
  use ExUnit.Case
  doctest FeedConsumer.Validator

  test "validate_outcomes check for completeness of odds (case: complete)" do
    match = %FeedConsumer.Struct.OddMatch{name: "Complete Outcomes", outcomes: %{"1" => 0.88, "x" => 1.2, "2" => 2.32}}

    result = FeedConsumer.Validator.validate_outcomes(match)

    assert result == {:ok, match}
  end

  test "validate_outcomes check for completeness of odds (case: incomplete)" do
    match = %FeedConsumer.Struct.OddMatch{name: "Incomplete Outcomes", outcomes: %{"1" => 0.88, "x" => 1.2}}

    result = FeedConsumer.Validator.validate_outcomes(match)

    assert result == {:error, match}
  end

  test "validate_outcomes check for completeness of odds (case: extraneous)" do
    match = %FeedConsumer.Struct.OddMatch{name: "Extraneous Outcomes", outcomes: %{"1" => 0.88, "x" => 1.2, "3" => 5, "2" => 1.2}}

    result = FeedConsumer.Validator.validate_outcomes(match)

    assert result == {:error, match}
  end

  test "validate_outcomes check for completeness of odds (case: extraneous + incomplete)" do
    match = %FeedConsumer.Struct.OddMatch{name: "Extraneous Outcomes", outcomes: %{"1" => 0.88, "x" => 1.2, "3" => 5}}
    result = FeedConsumer.Validator.validate_outcomes(match)

    assert result == {:error, match}
  end
end