defmodule AtlasIntegrationFixture.MixProject do
  use Mix.Project

  def project do
    [
      app: :atlas_integration_fixture,
      version: "0.0.0",
      elixir: "~> 1.14",
      deps: [{:ex_unit_atlas, path: "../../.."}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
