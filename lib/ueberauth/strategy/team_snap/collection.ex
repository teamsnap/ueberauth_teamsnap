defmodule Ueberauth.Strategy.TeamSnap.Collection do
  @moduledoc """
  Conveniences for dealing with Collection+JSON data.
  """

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

  def links(%{"links" => links}) when is_list(links), do: links(links)

  def links(links) when is_list(links) do
    links |> Enum.into(%{}, fn %{"href" => href, "rel" => rel} -> {rel, href} end)
  end

  def links(_), do: %{}
end
