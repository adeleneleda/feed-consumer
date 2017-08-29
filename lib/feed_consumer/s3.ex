defmodule FeedConsumer.S3 do
  @doc """
    Updates or creates (if does not exist yet) corresponding json file in S3
  """
  def update_match_json_file(filename, data) do
    IO.puts "[+] WRITING TO S3 #{ filename }"

    s3_bucket
    |> ExAws.S3.put_object("#{ filename }.json", data)
    |> ExAws.request
  end

  defp s3_bucket, do: Application.get_env(:feed_consumer, :s3_bucket)
end