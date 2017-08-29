defmodule FeedConsumer do
  use Application
  import Supervisor.Spec
  
  def start(_type, _args) do
    Supervisor.start_link([worker(FeedConsumer.Server, [])],
                          [strategy: :one_for_one, name: FeedConsumer.Supervisor])
  end
end