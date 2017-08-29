defmodule FeedConsumer.Struct.SchedMatch do
  @moduledoc """
    raw = %{
            "id" => 10678636,
            "team1_id" => 4890,
            "team2_id" => 6022,
            "team1_name" => "Germany",
            "team2_name" => "Czech Republic",
            "tournament_id" => 454,
            "kickoff_at" => 1497801600
          }
    FeedConsumer.Struct.SchedMatch.parse(raw)
  """
  defstruct [:id, :name, :team1_id, :team2_id, :team1_name, :team2_name, :tournament_id, :kickoff_at, :outcomes]

  def parse(%{} = input) do
    %__MODULE__{
      id:             input["id"],
      team1_id:       input["team1_id"],
      team2_id:       input["team2_id"],
      team1_name:     input["team1_name"],
      team2_name:     input["team2_name"],
      tournament_id:  input["tournament_id"],
      kickoff_at:     input["kickoff_at"],
      name:           input["team1_name"] <> " - " <> input["team2_name"]
    }
  end
end

defimpl Poison.Encoder, for: FeedConsumer.Struct.SchedMatch do
  def encode(%FeedConsumer.Struct.SchedMatch{outcomes: %{"1" => odd_1, "x" => odd_x, "2" => odd_2}} = match, _options) do
    data = [
              ~s("id": #{match.tournament_id}),
              ~s("home": "#{match.team1_name}"),
              ~s("away": "#{match.team2_name}"),
              ~s("outcomes": {"1": "#{ odd_1 }", "x": "#{ odd_x }", "2": "#{ odd_2 }"})
            ] |> Enum.join(", ")

    ~s({#{ data }})
  end
end