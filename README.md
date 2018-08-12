# Überauth TeamSnap

> TeamSnap OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [TeamSnap Authentication](https://auth.teamsnap.com).

1. Add `:ueberauth_team_snap` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_team_snap, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_team_snap]]
    end
    ```

1. Add TeamSnap to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        teamsnap: {Ueberauth.Strategy.TeamSnap, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.TeamSnap.OAuth,
      client_id: System.get_env("TEAM_SNAP_CLIENT_ID"),
      client_secret: System.get_env("TEAM_SNAP_CLIENT_SECRET")
    ```

1. Configure `:oauth2` to serialize `application/vnd.collection+json` content types:

    ```elixir
    config :oauth2,
      serializers: %{
        "application/json" => Poison,
        "application/vnd.collection+json" => Poison
      }
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/teamsnap

Or with options:

    /auth/teamsnap?scope=read+write

By default the requested scope is "read". This provides read access to the TeamSnap user profile details and teams. For a read-only scope, either use "read write" or a specific write scope, such as "read write_teams". See more at [TeamSnap's OAuth Documentation](http://developer.teamsnap.com/documentation/apiv3/authorization/#scopes). Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    teamsnap: {Ueberauth.Strategy.TeamSnap, [default_scope: "read write"]}
  ]
```

## License

Please see [LICENSE](https://github.com/mcrumm/ueberauth_team_snap/blob/master/LICENSE) for licensing details.
