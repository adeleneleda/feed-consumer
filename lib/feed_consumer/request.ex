defmodule FeedConsumer.Request do
  def get(url: url, type: "application/msgpack"), do: get(url: url, type: "application/msgpack", params: [])
  def get(url: url, type: "application/msgpack", params: params) do
    url
    |> HTTPoison.get(["Accept": "application/msgpack"], params: params)
    |> handle_msgpack_response
  end


  def get(url: url, type: "application/json"), do: get(url: url, type: "application/json", params: [])
  def get(url: url, type: "application/json", params: params) do
    url
    |> HTTPoison.get()
    |> handle_json_response()
  end

  def get(url) when is_binary(url) do
    get(url: url, type: "application/json")
  end

  def handle_msgpack_response({:ok, %{status_code: 200, body: body}}) do
    {:ok, Msgpax.unpack!(body)}
  end

  def handle_msgpack_response({:ok, %{status_code: 406, body: body}}) do
    {:ok, Msgpax.unpack!(body)}
  end

  def handle_json_response({:ok, %{status_code: 200, body: body}}) do
    {:ok, Poison.Parser.parse!(body)}
  end

  def handle_json_response({_, %{status_code: _, body: body}}) do
    {:error, Poison.Parser.parse!(body)}
  end
end