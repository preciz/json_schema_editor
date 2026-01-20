defmodule JSONSchemaEditor.MixProject do
  use Mix.Project

  @source_url "https://github.com/preciz/json_schema_editor"
  @version "0.7.2"

  def project do
    [
      app: :json_schema_editor,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      source_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    A Phoenix LiveComponent for visually building, editing, and validating JSON Schemas.
    """
  end

  defp package do
    [
      name: "json_schema_editor",
      files: ~w(lib assets .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 1.1"},
      {:stream_data, "~> 1.2", only: :test},
      {:ex_doc, "~> 0.39.3", only: :dev, runtime: false}
    ]
  end
end
