defmodule FeedConsumer.DataStore do

  alias  FeedConsumer.FileLogger
  import FeedConsumer.Validator, only: [validate_kickoff: 2]

   @moduledoc """
    Handles ETS calls for storage and retrieval of data
  """

  @doc """
    Creates new table :matches if not yet existent
    FeedConsumer.DataStore.setup
  """
  def setup do
    table_name
    |> table_exists?
    |> _setup
  end

  @doc """
    Transforms data to FeedConsumer.Struct.SchedMatch and saves to ETS under table_name

    {:ok, schedule} = FeedConsumer.Feed.fetch(:schedule)
    FeedConsumer.DataStore.cache(schedule)
  """
  def cache(data) do
    setup
    insert_into_table(data)
  end

  @doc """
    Looks up all values associated with given key
    iex> FeedConsumer.DataStore.lookup("Atletico Socopo - Deportivo Lara")
  """
  def lookup(key) do
    table_name
    |> :ets.lookup(key)
    |> Enum.map(fn({_id, value}) -> value end)
  end

  @doc """
    Looks up value associated with given key and returns the one with the closest kickoff that's within threshold
    iex> FeedConsumer.DataStore.lookup("Atletico Socopo - Deportivo Lara", 1503860400)
  """
  def lookup(key, kickoff) do
    setup

    key
    |> lookup
    |> log_if_no_match(key)
    |> validate_kickoff(kickoff)
  end

  def log_if_no_match([], key) do
    jaro_threshold = Application.get_env(:feed_consumer, :jaro_threshold)

    closest_match = FeedConsumer.DataStore.all
                    |> Enum.map(fn({k, _}) -> k end)
                    |> Enum.max_by(fn(k) -> String.jaro_distance(key, k) end)

    jaro_distance = String.jaro_distance(key, closest_match)

    if jaro_distance >= jaro_threshold, do: FileLogger.log_close_match([key, closest_match, jaro_distance])

    []
  end

  def log_if_no_match(results, _) when is_list(results), do: results

  def all,   do: :ets.tab2list(table_name)
  def count, do: length(all)

  defp insert_into_table([%{"team1_name" => team1, "team2_name" => team2} = head | tail]) do
    sched_match = FeedConsumer.Struct.SchedMatch.parse(head)

    two_way_insert(team1, team2, sched_match)

    team1
    |> FeedConsumer.Substitution.lookup
    |> Enum.each(&two_way_insert(&1, team2, sched_match))

    team2
    |> FeedConsumer.Substitution.lookup
    |> Enum.each(&two_way_insert(&1, team1, sched_match))

    insert_into_table(tail)
  end

  defp insert_into_table([]) do
    :ok
  end

  @doc """
    Goal: Increase match rate (can be removed if performance is more priority)
    Also save match info with team names interchanged (i.e. home - away)
  """
  defp two_way_insert(name1, name2, struct) do
    :ets.insert(table_name, {name1 <> " - " <> name2, struct})
    :ets.insert(table_name, {name2 <> " - " <> name1, struct})
  end

  # Table DNE
  defp _setup(false), do: :ets.new(table_name, [:public, :named_table, :bag])

  # Table Exists
  defp _setup(true), do: :ok

  defp table_exists?(name \\ table_name), do: if :ets.info(name) == :undefined, do: false, else: true

  defp table_name, do: Application.get_env(:feed_consumer, :ets_table)
end