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

    {:ok, assign(socket, schema: schema, json: initial_data, css: css_content, status: "Ready")}
  end

  def render(assigns) do
    ~H"""
    <style>
      body { margin: 0; font-family: sans-serif; background: #f0f2f5; }
      .custom-toolbar {
        background-color: #e0e7ff; /* Indigo-50 */
        border-radius: 4px;
        padding: 4px;
      }
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
    
    <div style="padding: 20px; max-width: 1200px; margin: 0 auto;">
       <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
         <h1>JSON Editor Demo</h1>
         <div style="background: white; padding: 10px; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.1);">
           <strong>Status:</strong> {@status}
         </div>
       </div>
       
       <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; height: 600px;">
         <div style="background: white; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); overflow: hidden;">
          <.live_component
            module={JSONSchemaEditor.JSONEditor}
            id="editor"
            schema={@schema}
            json={@json}
            on_save={fn updated_json -> send(self(), {:json_saved, updated_json}) end}
            on_change={fn updated_json -> send(self(), {:json_changed, updated_json}) end}
            toolbar_class="custom-toolbar"
          />
         </div>
         
         <div style="background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); overflow-y: auto;">
            <h3>Live Data View</h3>
            <JSONSchemaEditor.Viewer.render json={@json} style="font-size: 12px;" />
         </div>
       </div>
    </div>
    """
  end

  def handle_info({:json_saved, json}, socket) do
    {:noreply, assign(socket, json: json, status: "Saved at #{Time.to_string(Time.utc_now())}")}
  end

  def handle_info({:json_changed, json}, socket) do
    {:noreply, assign(socket, json: json, status: "Changed at #{Time.to_string(Time.utc_now())}")}
  end
end

PhoenixPlayground.start(live: JSONEditorDemo, port: 4041)
