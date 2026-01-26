Mix.install([
  {:phoenix_playground, "~> 0.1.0"},
  {:json_schema_editor, path: Path.expand("..", __DIR__)}
])

defmodule JSONEditorDemo do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    # Sample Schema
    schema = %{
      "$schema" => "https://json-schema.org/draft-07/schema",
      "title" => "Person",
      "type" => "object",
      "properties" => %{
        "firstName" => %{
          "type" => "string",
          "description" => "The person's first name."
        },
        "lastName" => %{
          "type" => "string",
          "description" => "The person's last name."
        },
        "age" => %{
          "description" => "Age in years which must be equal to or greater than zero.",
          "type" => "integer",
          "minimum" => 0
        },
        "hobbies" => %{
          "type" => "array",
          "items" => %{
            "type" => "string"
          }
        },
        "address" => %{
           "type" => "object",
           "properties" => %{
              "street" => %{"type" => "string"},
              "city" => %{"type" => "string"}
           },
           "required" => ["street", "city"]
        }
      },
      "required" => ["firstName", "lastName"]
    }
    
    # Initial Data
    initial_data = %{
       "firstName" => "John",
       "lastName" => "Doe",
       "age" => 25,
       "hobbies" => ["reading", "coding", "hiking"],
       "address" => %{
          "street" => "123 Main St",
          "city" => "Anytown"
       },
       "long_field" => "This is a ridiculously long string designed to test the limits of our UI truncation logic. It should show at least 20 more characters than before and eventually end with an ellipsis. " <> String.duplicate("Adding more text here to ensure it is really, really long. ", 5),
       "bio" => "Software Engineer.\n\nLoves Elixir and Phoenix.\n\nAlso enjoys long walks on the beach and writing very long sentences that span multiple lines just to test the multiline preview truncation logic.\n\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8"
    }

    css_path = Path.expand("../assets/css/json_schema_editor.css", __DIR__)
    css_content = File.read!(css_path)

    {:ok, assign(socket, schema: schema, json: initial_data, css: css_content)}
  end

  def render(assigns) do
    ~H"""
    <style>
      body { margin: 0; font-family: sans-serif; }
    </style>
    <style>
      <%= @css %>
    </style>
    <script>
      window.addEventListener("click", e => {
        const btn = e.target.closest(".jse-btn-copy");
        if (btn) {
          const content = btn.getAttribute("data-content");
          if (content) {
            navigator.clipboard.writeText(content).then(() => {
              btn.classList.add("jse-copied");
              const span = btn.querySelector("span");
              if (span) {
                const oldText = span.innerText;
                span.innerText = "Copied!";
                setTimeout(() => {
                  btn.classList.remove("jse-copied");
                  span.innerText = oldText;
                }, 2000);
              }
            });
          }
        }
      });
    </script>
    
    <div style="padding: 20px;">
       <h1>JSON Editor Demo</h1>
       <p>Edit the JSON below. It is validated against a schema.</p>
       
       <div style="height: 600px; border: 1px solid #ddd;">
        <.live_component
          module={JSONSchemaEditor.JSONEditor}
          id="editor"
          schema={@schema}
          json={@json}
          on_save={fn updated_json -> send(self(), {:json_updated, updated_json}) end}
        />
       </div>
    </div>
    """
  end

  def handle_info({:json_updated, json}, socket) do
    IO.puts("JSON Saved: #{inspect(json)}")
    {:noreply, assign(socket, json: json)}
  end
end

PhoenixPlayground.start(live: JSONEditorDemo, port: 4041)
