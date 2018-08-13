defmodule Ueberauth.Strategy.TeamSnap.Collection do
  @moduledoc """
  Conveniences for dealing with Collection+JSON data.
  """

  @doc """
  Returns the first item in the given collection.
  """
  def first(%{"collection" => %{"items" => [item | _]}}), do: item
  def first(_), do: nil

  @doc """
  Returns a flat map for a collection or data structure.
  """
  def flatten(%{"collection" => %{"links" => links, "items" => items}} = object) do
    Map.merge(object, %{
      "links" => flatten(links),
      "items" => flatten(items)
    })
  end

  def flatten(%{"data" => data, "links" => links} = object) do
    Map.merge(object, %{
      "data" => flatten(data),
      "links" => flatten(links)
    })
  end

  def flatten(%{"data" => data} = object) do
    object |> Map.put("data", flatten(data))
  end

  def flatten(data) when is_list(data) or is_map(data) do
    Enum.into(data, %{}, &do_flatten/1)
  end

  defp do_flatten(%{"name" => name, "value" => value}), do: {name, value}
  defp do_flatten(%{"rel" => rel, "href" => href}), do: {rel, href}

  @doc """
  Returns a link by its `rel`.
  """
  def link(response, rel) when is_binary(rel) do
    with links <- links(response),
         true <- Map.has_key?(links, rel) do
      {:ok, links[rel]}
    else
      false ->
        {:error, "link", "#{rel} not found"}
    end
  end

  @doc """
  Returns a map of `links` from the collection.
  """
  def links(collection)
  def links(%{"collection" => collection}), do: links(collection)
  def links(%{"links" => links}) when is_list(links), do: flatten(links)
  def links(links) when is_list(links), do: flatten(links)
  def links(_), do: %{}
end
