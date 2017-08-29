defmodule FeedConsumer.Substitution do
  @doc """
    FeedConsumer.Substitution.lookup("Darlington FC")
  """
  def lookup(name) do
    data[name] || []
  end

  def data do
    %{
      "Darlington 1883" => ["Darlington FC"],
      "Darlington FC"   => ["Darlington 1883"]
    }
  end
end