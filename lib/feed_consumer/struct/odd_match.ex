defmodule FeedConsumer.Struct.OddMatch do
  defstruct [:name, :kickoff, :outcomes]

  @doc """
    > raw =  %{
      "kickOf" => 1503838800, 
      "name" => "Sony Sugar FC - Kariobangi Sharks",
      "outcomes" => 
        [
          ["131046198", "1", "2.5"], 
          ["95849038", "2", "2.88"],
          ["35440182", "x", "2.75"]
        ]
      }

    > FeedConsumer.Struct.OddMatch.parse(raw)
    %FeedConsumer.Struct.OddMatch{kickoff: 1503838800, name: "Sony Sugar FC - Kariobangi Sharks", outcomes: %{"1" => "2.5", "2" => "2.88", "x" => "2.75"}}
  """
  def parse(%{} = input) do
    parsed_outcomes = parse_outcomes(input["outcomes"])

    %__MODULE__{
      name:      input["name"],
      kickoff:   input["kickOf"],
      outcomes:  parsed_outcomes,
    }
  end

  @doc """
    End Goal: %{"1" => odd_1, "x" => odd_x, "2" => odd_2}

    Parses raw odds array by creating a tuple with the 2nd (side) and 3rd (odd) elements

    ## Examples

    iex> outcomes = [["114585828", "1", "2.14"], ["92239542",  "2", "2.88"], ["121837756", "x", "2.88"]]
    iex> FeedConsumer.Struct.OddMatch.parse_outcomes(outcomes)
    %{"1" => "2.14", "2" => "2.88", "x" => "2.88"}
  """
  def parse_outcomes(outcomes) do
    Enum.into(outcomes, %{}, fn([_, side, odd]) -> {side, odd} end )
  end
end