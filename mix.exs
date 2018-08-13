defmodule Ueberauth.TeamSnap.Mixfile do
  use Mix.Project

  @version "0.1.0"

  @github_url "https://github.com/mcrumm/ueberauth_team_snap"

  def project do
    [
      app: :ueberauth_team_snap,
      version: @version,
      name: "Ueberauth TeamSnap",
      package: package(),
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: @github_url,
      homepage_url: @github_url,
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:oauth2, "~> 0.9"},
      {:ueberauth, "~> 0.4"},

      # dev/test only dependencies
      {:credo, "~> 0.8", only: [:dev, :test]},

      # docs dependencies
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md"]]
  end

  defp description do
    "An Ueberauth strategy for using TeamSnap to authenticate your users."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Michael Crumm"],
      licenses: ["MIT"],
      links: %{GitHub: @github_url}
    ]
  end
end
