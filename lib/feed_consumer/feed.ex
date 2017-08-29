defmodule FeedConsumer.Feed do
  require Logger

  alias FeedConsumer.DataStore
  alias FeedConsumer.FileLogger
  alias FeedConsumer.Struct.OddMatch

  import FeedConsumer.Request,   only: [get: 1]
  import FeedConsumer.Validator, only: [validate_outcomes: 1]

  @doc """
    odds = FeedConsumer.Feed.get_odds
  """
  def fetch(:odds), do: get(odds_url)

  @doc """
    FeedConsumer.Feed.fetch(:schedule)
  """
  def fetch(:schedule, timestamp) do
    get(url: schedule_url, type: "application/msgpack", params: %{last_checked_at: timestamp})
  end

  @doc """
    Fetches schedule from schedule_url, transforms it to have the match name as key, and saves it to ETS for caching

    FeedConsumer.Feed.get_schedule
  """
  def get_schedule(timestamp \\ :os.system_time(:seconds) - 170_000) do
    :schedule
    |> fetch(timestamp)
    |> process_schedule
  end

  @doc """
    Transforms and saves given schedule data to ETS
  """
  def process_schedule({:ok, %{"error" => message}}), do: {:error, message}
  def process_schedule({:ok, schedule}) do
    FileLogger.log_action("FETCHED SCHEDULE (New: #{ length(schedule) })")

    DataStore.cache(schedule)
  end

  @doc """
    Gets odds from odds_url and processes each

    FeedConsumer.Feed.get_odds
  """
  def get_odds do
    :odds
    |> fetch
    |> process_odds
  end

  @doc """
    Extracts the values from the resulting map of the fetch(:odds) call and iterates through each for processing

    ### Examples
    odds = %{"11267424" => 
              %{
                "kickOf" => 1503838800, 
                "name" => "Sony Sugar FC - Kariobangi Sharks",
                "outcomes" => 
                  [
                    ["131046198", "1", "2.5"], 
                    ["95849038", "2", "2.88"],
                    ["35440182", "x", "2.75"]
                  ]
                }
              }

    FeedConsumer.Feed.process_odds({:ok, odds})
  """
  def process_odds({:ok, odds}) do
    FileLogger.log_action("FETCHED ODDS (Odds: #{ map_size(odds) } | Matches: #{ FeedConsumer.DataStore.count })")
    odds
    |> Map.values
    |> process_match_odds
  end

  @doc """
    Handles individual transformed match data from odds_url (i.e. parsing, validation, and S3 saving)
  """
  def process_match_odds([%{"outcomes" => outcomes} = head | tail]) do
    head
    |> OddMatch.parse
    |> validate_outcomes
    |> _process_match_odd

    Logger.info("[+] Remaining Odds to Process: #{ length(tail)}")

    process_match_odds(tail)
  end

  def process_match_odds([]), do: nil

  defp _process_match_odd({:error, %OddMatch{name: name, outcomes: outcomes}}) do
    FileLogger.log_invalid_outcomes([name, inspect(outcomes)])
  end

  defp _process_match_odd({:ok, %OddMatch{name: name, kickoff: kickoff, outcomes: outcomes}}) do 
    name
    |> find_match_in_schedule(kickoff)
    |> format_match_data(outcomes)
    |> update_match_record
  end

  defp find_match_in_schedule(name, odd_kickoff), do: DataStore.lookup(name, odd_kickoff)

  defp update_match_record({our_id, {:ok, data}}), do: FeedConsumer.S3.update_match_json_file(our_id, data)
  defp update_match_record(_), do: nil

  defp format_match_data(nil, _), do: nil
  defp format_match_data(%FeedConsumer.Struct.SchedMatch{} = match, outcomes) do
    {
      match.id,
      match
      |> Map.put(:outcomes, outcomes)
      |> Poison.encode
    }
  end

  defp odds_url,     do: Application.get_env(:feed_consumer, :odds_url)
  defp schedule_url, do: Application.get_env(:feed_consumer, :schedule_url)
end