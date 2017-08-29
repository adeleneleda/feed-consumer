defmodule FeedConsumer.Struct.OddMatchTest do
  use ExUnit.Case
  doctest FeedConsumer.Struct.OddMatch

  test "OddMatch.parse returns correct struct" do
    raw =  %{
      "kickOf" => 1503838800, 
      "name" => "Sony Sugar FC - Kariobangi Sharks",
      "outcomes" => 
        [
          ["131046198", "1", "2.5"], 
          ["95849038", "2", "2.88"],
          ["35440182", "x", "2.75"]
        ]
    }

    result = FeedConsumer.Struct.OddMatch.parse(raw)
    assert result = %FeedConsumer.Struct.OddMatch{kickoff: 1503838800, 
                                                  name: "Sony Sugar FC - Kariobangi Sharks", 
                                                  outcomes: %{"1" => "2.5", "2" => "2.88", "x" => "2.75"}}
  end
end
