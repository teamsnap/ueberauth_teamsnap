defmodule Ueberauth.Strategy.TeamSnap.OAuth do
  @moduledoc """
  An implementation of OAuth2 for TeamSnap.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.TeamSnap.OAuth,
        client_id: System.get_env("TEAM_SNAP_CLIENT_ID"),
        client_secret: System.get_env("TEAM_SNAP_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  alias OAuth2.{
    AccessToken,
    Client,
    Strategy.AuthCode
  }

  @defaults [strategy: __MODULE__, site: "https://auth.teamsnap.com"]

  @doc """
  Construct a client for requests to TeamSnap.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.TeamSnap.OAuth.client(redirect_uri: "http://localhost:4000/auth/teamsnap/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.TeamSnap`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.TeamSnap.OAuth)
      |> check_config_key_exists(:client_id)
      |> check_config_key_exists(:client_secret)

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    Client.new(client_opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client = client(Keyword.get(options, :client_options, []))

    client
    |> Client.get_token!(params, headers, options)
    |> Map.fetch!(:token)
  end

  @doc """
  Determines if the access token has expired.
  """
  defdelegate token_expired?(token), to: AccessToken, as: :expired?

  @doc """
  Returns true if the access token can expire, false otherwise.
  """
  defdelegate token_expires?(token), to: AccessToken, as: :expires?

  # Strategy Callbacks

  defdelegate authorize_url(client, params), to: AuthCode

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> AuthCode.get_token(params, headers)
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.TeamSnap"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.TeamSnap is not a keyword list, as expected"
  end
end
