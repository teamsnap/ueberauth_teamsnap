defmodule Ueberauth.Strategy.TeamSnap do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with TeamSnap.

  ### Setup

  Create an application in TeamSnap for you to use.

  Register a new application at: [TeamSnap Authentication](https://auth.teamsnap.com/oauth/applications) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          teamsnap: {Ueberauth.Strategy.TeamSnap, []}
        ]

  Then include the configuration for TeamSnap.

      config :ueberauth, Ueberauth.Strategy.TeamSnap.OAuth,
        client_id: System.get_env("TEAM_SNAP_CLIENT_ID"),
        client_secret: System.get_env("TEAM_SNAP_CLIENT_SECRET")

  Configure `:oauth2` to serialize Collection+JSON data. If you're using Poison, your configuartion will look like this:

      config :oauth2,
        serializers: %{
          "application/json" => Poison,
          "application/vnd.collection+json" => Poison
        }

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.Plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the `uid_field`

      config :ueberauth, Ueberauth,
        providers: [
          teamsnap: {Ueberauth.Strategy.TeamSnap, [uid_field: :email]}
        ]

  Default is `:id`

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          teamsnap: {Ueberauth.Strategy.TeamSnap, [default_scope: "read write_members write_teams"]}
        ]

  Default is `read`. To use multiple scopes, pass a space-separated list to the scope parameter.
  """
  use Ueberauth.Strategy,
    uid_field: :id,
    default_scope: "read",
    oauth2_module: Ueberauth.Strategy.TeamSnap.OAuth

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Info
  alias Ueberauth.Strategy.TeamSnap.OAuth

  @doc """
  Handles the initial redirect to the TeamSnap Authentication page.

  To customize the scope (permissions) that are requested by TeamSnap include them as part of your url:

      "/auth/teamsnap?scope=read+write"
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from TeamSnap. When there is a failure from TeamSnap the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from TeamSnap is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    # TeamSnap requires the redirect_uri during token exchange
    opts = [options: [client_options: [redirect_uri: callback_url(conn)]]]

    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code], opts])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      conn
      |> put_private(:team_snap_token, token)
      |> fetch_user(token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw TeamSnap response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:team_snap_user, nil)
    |> put_private(:team_snap_token, nil)
  end

  @doc """
  Fetches the uid field from the TeamSnap response. This defaults to the option `uid_field` which in-turn defaults to `id`
  """
  def uid(conn) do
    conn |> option(:uid_field) |> to_string() |> fetch_uid(conn)
  end

  @doc """
  Includes the credentials from the TeamSnap response.
  """
  def credentials(conn) do
    token = conn.private.team_snap_token
    scopes = (token.other_params["scope"] || "") |> String.split(" ")

    module = option(conn, :oauth2_module)
    expires? = apply(module, :token_expires?, [token])

    %Credentials{
      token: token.access_token,
      token_type: token.token_type,
      expires: expires?,
      expires_at: token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.team_snap_user

    %Info{
      name: user["name"],
      description: user["bio"],
      nickname: user["login"],
      email: user["email"],
      location: user["location"],
      urls: %{}
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the TeamSnap callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.team_snap_token,
        user: conn.private.team_snap_user
      }
    }
  end

  defp fetch_uid(field, conn) do
    conn.private.team_snap_user[field]
  end

  defp fetch_user(conn, token) do
    with {:ok, %OAuth2.Response{status_code: status_code, body: user}}
         when status_code in 200..399 <- OAuth.get(token, "https://api.teamsnap.com/v3/me") do
      put_private(conn, :team_snap_user, user)
    else
      {:ok, %OAuth2.Response{status_code: 401}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
