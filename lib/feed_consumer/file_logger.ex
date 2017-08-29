defmodule FeedConsumer.FileLogger do
  @close_matches_file_path         "close-matches.log"
  @kickoff_mismatches_file_path    "kickoff-mismatches.log"
  @invalid_outcomes_file_path      "invalid-outcomes.log"
  @actions_file_path               "actions.log"

  def log_close_match(data),          do: log(@close_matches_file_path, data)
  def log_kickoff_mismatch(data),     do: log(@kickoff_mismatches_file_path, data)
  def log_invalid_outcomes(data),     do: log(@invalid_outcomes_file_path, data)
  def log_action(data),               do: log(@actions_file_path, data)

  defp log(filename, data) when is_list(data) do
    data_str = data
               |> Enum.map(&inspect/1)
               |> Enum.join(" | ")

    log(filename, data_str)
  end

  defp log(filename, data) do
    filename
    |> open
    |> write(data)
    |> File.close
  end

  defp open(filename) do
    {:ok, file} = File.open filename, [:append]

    file
  end

  defp write(file, data) do
    IO.puts(file, "[#{ time_now }] #{ data }")

    file
  end

  defp time_now do
    DateTime.utc_now |> DateTime.to_iso8601()
  end
end