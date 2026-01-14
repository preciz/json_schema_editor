Mix.install([
  {:phoenix_playground, "~> 0.1.0"},
  {:json_schema_editor, path: Path.expand("..", __DIR__)}
])

defmodule Demo do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    schema = %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "age" => %{"type" => "integer"},
        "tags" => %{"type" => "array"}
      }
    }

    css_path = Path.expand("../assets/css/json_schema_editor.css", __DIR__)
    css_content = File.read!(css_path)

    {:ok, assign(socket, my_schema: schema, css: css_content)}
  end

  def render(assigns) do
    ~H"""
    <style>
      <%= @css %>
    </style>
    <div style="height: 100vh; display: flex; flex-direction: column;">
      <div style="padding: 1rem; border-bottom: 1px solid #eee;">
        <h1>JSON Schema Editor Demo</h1>
      </div>
      <div style="flex: 1; padding: 2rem; overflow: auto;">
        <.live_component
          module={JSONSchemaEditor}
          id="editor"
          schema={@my_schema}
          on_save={fn updated_json -> send(self(), {:schema_updated, updated_json}) end}
        />
      </div>
    </div>
    """
  end

  def handle_info({:schema_updated, schema}, socket) do
    {:noreply, assign(socket, my_schema: schema)}
  end
end

PhoenixPlayground.start(live: Demo, port: 4040)
