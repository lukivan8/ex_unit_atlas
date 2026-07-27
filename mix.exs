defmodule ExUnitAtlas.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/lukivan8/ex_unit_atlas"

  def project do
    [
      app: :ex_unit_atlas,
      version: @version,
      elixir: "~> 1.14",
      deps: deps(),
      description: "Turn regular ExUnit tests into readable behavior reports",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/ex_unit_atlas",
        "Source" => @source_url
      },
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "RELEASING.md",
        "CONTRIBUTING.md",
        "CODE_OF_CONDUCT.md",
        "SECURITY.md",
        "SUPPORT.md",
        "LICENSE",
        "docs"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "docs/getting-started.md",
        "docs/report-format.md",
        "docs/architecture.md",
        "docs/exunit-integration.md",
        "docs/hypothesis-result.md",
        "docs/roadmap.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "CODE_OF_CONDUCT.md",
        "SECURITY.md",
        "SUPPORT.md",
        "RELEASING.md"
      ],
      groups_for_extras: [
        Guides: [
          "docs/getting-started.md",
          "docs/report-format.md",
          "docs/architecture.md",
          "docs/exunit-integration.md",
          "docs/hypothesis-result.md",
          "docs/roadmap.md"
        ],
        Community: [
          "CONTRIBUTING.md",
          "CODE_OF_CONDUCT.md",
          "SECURITY.md",
          "SUPPORT.md"
        ],
        Maintainers: ["RELEASING.md"]
      ]
    ]
  end
end
