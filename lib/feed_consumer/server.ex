defmodule FeedConsumer.Server do
  use GenServer
  require Logger

  def start_link, do: GenServer.start_link(__MODULE__, time_now)

   def init(timestamp) do
    log("Initializing Server...")

    get_match_schedule(:os.system_time(:seconds) - 170_000) # Two Days for initialization (max that we can get from Match API)
    schedule_odds_fetch()

    {:ok, timestamp}
  end

  def get_match_schedule(timestamp) do
    log("Fetching Match Schedule...")

    GenServer.cast(__MODULE__, {:update_timestamp, time_now})
    schedule_sched_fetch()

    FeedConsumer.Feed.get_schedule(timestamp)
  end

  def handle_cast({:update_timestamp, timestamp}) do
    log("Updating Timestamp...")
    {:noreply, timestamp}
  end

  def handle_info(:get_odds, timestamp) do
    log("Fetching Match Odds...")

    schedule_odds_fetch()
    FeedConsumer.Feed.get_odds

    {:noreply, timestamp}
  end

  def handle_info(:get_matches, timestamp) do
    get_match_schedule(timestamp)

    {:noreply, timestamp}
  end

  def log(message), do: Logger.info("#{ __MODULE__ }: #{ message }")

  def schedule_odds_fetch,  do: Process.send_after(self(), :get_odds, 60_000)
  def schedule_sched_fetch, do: Process.send_after(self(), :get_matches, 1_200_000)

  # HELPER
  defp time_now,                 do: :os.system_time(:seconds)
  defp schedule_reload_interval, do: Application.get_env(:feed_consumer, :schedule_reload_interval)
end