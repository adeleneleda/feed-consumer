defmodule FeedConsumer.Validator do
  @moduledoc """
    Module of validator functions
  """
  alias FeedConsumer.FileLogger
  alias FeedConsumer.Struct.OddMatch

  @doc """
    Returns {:ok, match} if outcomes are complete (i.e. has odd for 1, x, and 2) else returns {:error, match}
  """
  def validate_outcomes(%OddMatch{outcomes: outcomes} = match) do
    keys = outcomes 
           |> Map.keys
           |> Enum.map(&String.downcase/1)
           |> Enum.sort

    case keys do
      ["1", "2", "x"] -> {:ok,    match}
      _               -> {:error, match}
    end
  end

  @doc """
    Returns given match if within kickoff threshold, else nil
  """
  def validate_kickoff(%FeedConsumer.Struct.SchedMatch{} = match, kickoff) do
    case check_kickoff_times(match.kickoff_at, kickoff) do
      {:ok, _} -> 
        match
      {:error, diff} ->
        FileLogger.log_kickoff_mismatch([match.id, match.name, match.kickoff_at, kickoff, diff])
        nil
    end
  end

  def validate_kickoff([], _kickoff), do: nil

  def validate_kickoff(results, kickoff) when is_list(results) do
    results
    |> Enum.min_by(&(abs(&1.kickoff_at - kickoff)))
    |> validate_kickoff(kickoff)
  end

  def check_kickoff_times(kickoff1, kickoff2) do
    diff = abs(kickoff1 - kickoff2)

    case diff <= kickoff_threshold do
      true  -> {:ok, diff}
      false -> {:error, diff}
    end
  end

  def kickoff_threshold, do: Application.get_env(:feed_consumer, :kickoff_threshold)
end