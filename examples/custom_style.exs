Mix.install([
  {:phoenix_playground, "~> 0.1.0"},
  {:json_schema_editor, path: Path.expand("..", __DIR__)}
])

defmodule CustomStyleDemo do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    schema = %{
      "$schema" => "https://json-schema.org/draft-07/schema",
      "title" => "Styled Schema",
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "active" => %{"type" => "boolean"}
      }
    }

    css_path = Path.expand("../assets/css/json_schema_editor.css", __DIR__)
    css_content = File.read!(css_path)

    {:ok, assign(socket, my_schema: schema, css: css_content)}
  end

  def render(assigns) do
    ~H"""
    <style>
      body {
        margin: 0;
        padding: 40px;
        font-family: system-ui, sans-serif;
        background-color: #f0fdf4; /* Green-50 */
      }
      
      .container {
        max-width: 800px;
        margin: 0 auto;
        background: white;
        padding: 20px;
        border-radius: 12px;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
      }

      /* Customizing the editor via CSS variables */
      .emerald-theme {
        --jse-primary: #10b981; /* Emerald-500 */
        --jse-primary-hover: #059669; /* Emerald-600 */
        --jse-border-focus: #10b981;
        --jse-bg-secondary: #f0fdf4;
        --jse-radius: 1rem;
      }
      
      .emerald-header {
        background-color: #064e3b !important; /* Emerald-900 */
        color: white !important;
        border-radius: 1rem 1rem 0 0;
      }
      
      .emerald-header .jse-tab-btn {
        color: #a7f3d0 !important;
      }
      
      .emerald-header .jse-tab-btn.active {
        background-color: #059669 !important;
        color: white !important;
      }

      .emerald-toolbar {
        gap: 1rem !important;
      }
    </style>
    <style>
      <%= @css %>
    </style>
    
    <div class="container">
      <h1>Custom Styling Demo</h1>
      <p>This example demonstrates how to use CSS variables and custom classes to style the editor.</p>
      
      <div style="height: 500px; border: 1px solid #e5e7eb; border-radius: 1rem; overflow: hidden;">
        <.live_component
          module={JSONSchemaEditor}
          id="editor"
          schema={@my_schema}
          class="emerald-theme"
          header_class="emerald-header"
          toolbar_class="emerald-toolbar"
        />
      </div>
    </div>
    """
  end
end

PhoenixPlayground.start(live: CustomStyleDemo, port: 4042)
