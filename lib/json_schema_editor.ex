defmodule JSONSchemaEditor do
  @moduledoc """
  A Phoenix LiveComponent for visually editing JSON Schemas.

  ## Attributes

    * `schema` - The JSON Schema to edit (required).
    * `on_save` - A callback function that will be called when the schema is updated.
      It receives the updated schema as a map.
    * `id` - The unique identifier for the component.

  ## Examples

      <.live_component
        module={JSONSchemaEditor}
        id="json-editor"
        schema={@my_schema}
        on_save={fn updated_schema -> send(self(), {:schema_saved, updated_schema}) end}
      />
  """
  use Phoenix.LiveComponent
  alias JSONSchemaEditor.SchemaUtils
  alias JSONSchemaEditor.Validator
  alias JSONSchemaEditor.PrettyPrinter
  alias JSONSchemaEditor.Components

  @types ["string", "number", "integer", "boolean", "object", "array"]
  @logic_types ["anyOf", "oneOf", "allOf"]
  @formats ["email", "date-time", "date", "time", "uri", "uuid", "ipv4", "ipv6", "hostname"]

  @doc """
  Initializes the component with the given assigns.
  """
  def update(assigns, socket) do
    # Keys that should be assigned directly to socket.assigns
    known_keys = [:id, :schema, :on_save, :ui_state, :active_tab, :myself, :class]
    {known_assigns, rest} = Map.split(assigns, known_keys)

    socket =
      socket
      |> assign(known_assigns)
      |> assign_new(:class, fn -> nil end)
      |> assign(:rest, Map.merge(Map.get(socket.assigns, :rest, %{}), rest))
      |> assign_new(:ui_state, fn -> %{} end)
      |> assign_new(:schema, fn -> %{} end)
      |> update(:schema, &Map.put_new(&1, "$schema", "https://json-schema.org/draft-07/schema"))
      |> assign(types: @types, formats: @formats, logic_types: @logic_types)
      |> assign_new(:active_tab, fn -> :editor end)
      |> validate_and_assign_errors()

    {:ok, socket}
  end

  defp validate_and_assign_errors(socket) do
    errors = Validator.validate_schema(socket.assigns.schema)
    assign(socket, :validation_errors, errors)
  end

  def handle_event("change_schema", %{"value" => schema_uri}, socket) do
    socket =
      update_schema(socket, JSON.encode!([]), fn node ->
        if schema_uri == "" do
          Map.delete(node, "$schema")
        else
          Map.put(node, "$schema", schema_uri)
        end
      end)

    {:noreply, socket}
  end

  def handle_event("change_format", %{"path" => path_json, "value" => format}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        if format == "" do
          Map.delete(node, "format")
        else
          Map.put(node, "format", format)
        end
      end)

    {:noreply, socket}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("change_type", %{"path" => path_json, "type" => new_type}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        # Clean up existing conflicting keys
        base =
          Map.drop(node, ["type", "properties", "required", "items", "anyOf", "oneOf", "allOf"])

        case new_type do
          "object" -> Map.merge(base, %{"type" => "object", "properties" => %{}})
          "array" -> Map.merge(base, %{"type" => "array", "items" => %{"type" => "string"}})
          logic when logic in @logic_types -> Map.put(base, logic, [%{"type" => "string"}])
          _ -> Map.put(base, "type", new_type)
        end
      end)

    {:noreply, socket}
  end

  def handle_event("add_property", %{"path" => path_json}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        props = Map.get(node, "properties", %{})
        new_key = SchemaUtils.generate_unique_key(props, "new_field")
        Map.put(node, "properties", Map.put(props, new_key, %{"type" => "string"}))
      end)

    {:noreply, socket}
  end

  def handle_event("delete_property", %{"path" => path_json, "key" => key}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        new_props = Map.delete(Map.get(node, "properties", %{}), key)
        new_required = List.delete(Map.get(node, "required", []), key)

        node
        |> Map.put("properties", new_props)
        |> Map.put("required", new_required)
      end)

    {:noreply, socket}
  end

  def handle_event("toggle_required", %{"path" => path_json, "key" => key}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        current_required = Map.get(node, "required", [])

        new_required =
          if key in current_required do
            List.delete(current_required, key)
          else
            current_required ++ [key]
          end

        Map.put(node, "required", new_required)
      end)

    {:noreply, socket}
  end

  def handle_event(
        "rename_property",
        %{"path" => path_json, "old_key" => old_key, "value" => new_key},
        socket
      ) do
    new_key = String.trim(new_key)

    if new_key == "" or new_key == old_key do
      {:noreply, socket}
    else
      socket =
        update_schema(socket, path_json, fn node ->
          current_props = Map.get(node, "properties", %{})

          if Map.has_key?(current_props, new_key) do
            node
          else
            {value, remaining} = Map.pop(current_props, old_key)
            new_props = Map.put(remaining, new_key, value)

            current_required = Map.get(node, "required", [])

            new_required =
              Enum.map(current_required, fn k ->
                if k == old_key, do: new_key, else: k
              end)

            node
            |> Map.put("properties", new_props)
            |> Map.put("required", new_required)
          end
        end)

      {:noreply, socket}
    end
  end

  def handle_event("change_title", %{"path" => path_json, "value" => title}, socket) do
    {:noreply, update_node_field(socket, path_json, "title", String.trim(title))}
  end

  def handle_event("change_description", %{"path" => path_json, "value" => description}, socket) do
    {:noreply, update_node_field(socket, path_json, "description", String.trim(description))}
  end

  def handle_event("toggle_ui", %{"path" => path_json, "type" => type}, socket) do
    ui_state = Map.update(socket.assigns.ui_state, "#{type}:#{path_json}", true, &(!&1))
    {:noreply, assign(socket, :ui_state, ui_state)}
  end

  def handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => f, "value" => v},
        socket
      ) do
    {:noreply, update_node_field(socket, path_json, f, SchemaUtils.cast_value(f, v))}
  end

  def handle_event("update_const", %{"path" => path_json, "value" => value}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        if value == "" do
          Map.delete(node, "const")
        else
          Map.put(node, "const", SchemaUtils.cast_value(Map.get(node, "type", "string"), value))
        end
      end)

    {:noreply, socket}
  end

  def handle_event("add_enum_value", %{"path" => path_json}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        current_enum = Map.get(node, "enum", [])
        type = Map.get(node, "type", "string")

        default_value =
          case type do
            "number" -> 0.0
            "integer" -> 0
            "boolean" -> true
            _ -> "new value"
          end

        Map.put(node, "enum", current_enum ++ [default_value])
      end)

    {:noreply, socket}
  end

  def handle_event("remove_enum_value", %{"path" => path_json, "index" => index}, socket) do
    index = String.to_integer(index)

    socket =
      update_schema(socket, path_json, fn node ->
        current_enum = Map.get(node, "enum", [])
        new_enum = List.delete_at(current_enum, index)

        if new_enum == [] do
          Map.delete(node, "enum")
        else
          Map.put(node, "enum", new_enum)
        end
      end)

    {:noreply, socket}
  end

  def handle_event(
        "update_enum_value",
        %{"path" => path_json, "index" => index, "value" => value},
        socket
      ) do
    index = String.to_integer(index)

    socket =
      update_schema(socket, path_json, fn node ->
        current_enum = Map.get(node, "enum", [])
        type = Map.get(node, "type", "string")
        casted_value = SchemaUtils.cast_value(type, value)

        new_enum = List.replace_at(current_enum, index, casted_value)
        Map.put(node, "enum", new_enum)
      end)

    {:noreply, socket}
  end

  def handle_event("add_logic_branch", %{"path" => path_json, "type" => logic_type}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        branches = Map.get(node, logic_type, [])
        Map.put(node, logic_type, branches ++ [%{"type" => "string"}])
      end)

    {:noreply, socket}
  end

  def handle_event(
        "remove_logic_branch",
        %{"path" => path_json, "type" => logic_type, "index" => index},
        socket
      ) do
    index = String.to_integer(index)

    socket =
      update_schema(socket, path_json, fn node ->
        branches = Map.get(node, logic_type, [])
        new_branches = List.delete_at(branches, index)

        if new_branches == [] do
          # Revert to a basic type if all branches are gone
          Map.delete(node, logic_type) |> Map.put("type", "string")
        else
          Map.put(node, logic_type, new_branches)
        end
      end)

    {:noreply, socket}
  end

  def handle_event("toggle_additional_properties", %{"path" => path_json}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        case Map.get(node, "additionalProperties") do
          false -> Map.delete(node, "additionalProperties")
          _ -> Map.put(node, "additionalProperties", false)
        end
      end)

    {:noreply, socket}
  end

  def handle_event("add_contains", %{"path" => path_json}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        Map.put(node, "contains", %{"type" => "string"})
      end)

    {:noreply, socket}
  end

  def handle_event("remove_contains", %{"path" => path_json}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        Map.delete(node, "contains")
      end)

    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    if Enum.empty?(socket.assigns.validation_errors) and socket.assigns[:on_save] do
      socket.assigns.on_save.(socket.assigns.schema)
    end

    {:noreply, socket}
  end

  defp update_schema(socket, path_json, update_fn) do
    path = JSON.decode!(path_json)
    schema = SchemaUtils.update_in_path(socket.assigns.schema, path, update_fn)

    socket
    |> assign(:schema, schema)
    |> validate_and_assign_errors()
  end

  defp update_node_field(socket, path_json, field, value) do
    update_schema(socket, path_json, fn node ->
      if value in [nil, "", false] do
        Map.delete(node, field)
      else
        Map.put(node, field, value)
      end
    end)
  end

  def render(assigns) do
    assigns =
      assigns
      |> assign(:types, @types)
      |> assign(:logic_types, @logic_types)

    ~H"""
    <div id={@id} class={["jse-host", @class]} {@rest}>
      <div class="jse-container">
        <div class="jse-header">
          <div class="jse-tabs">
            <button
              class={["jse-tab-btn", @active_tab == :editor && "active"]}
              phx-click="switch_tab"
              phx-value-tab="editor"
              phx-target={@myself}
            >
              Visual Editor
            </button>
            <button
              class={["jse-tab-btn", @active_tab == :preview && "active"]}
              phx-click="switch_tab"
              phx-value-tab="preview"
              phx-target={@myself}
            >
              JSON Preview
            </button>
          </div>

          <div class="jse-schema-selector">
            <label for={"#{@id}-schema-uri"}>$schema</label>
            <input
              type="text"
              id={"#{@id}-schema-uri"}
              value={Map.get(@schema, "$schema")}
              phx-blur="change_schema"
              phx-target={@myself}
              placeholder="Schema URI..."
            />
          </div>

          <button
            class="jse-btn jse-btn-primary"
            phx-click="save"
            phx-target={@myself}
            disabled={not Enum.empty?(@validation_errors)}
          >
            <span>Save</span>
            <Components.icon name={:save} />
          </button>
        </div>

        <div class="jse-content-area">
          <%= if @active_tab == :editor do %>
            <div class="jse-editor-pane">
              <Components.render_node
                node={@schema}
                path={[]}
                ui_state={@ui_state}
                validation_errors={@validation_errors}
                types={@types}
                logic_types={@logic_types}
                formats={@formats}
                myself={@myself}
              />
            </div>
          <% end %>

          <%= if @active_tab == :preview do %>
            <div class="jse-preview-panel">
              <div class="jse-preview-header">
                <span>Current Schema</span>
                <button
                  class="jse-btn-copy"
                  id={"#{@id}-copy-btn"}
                  phx-hook="JSONSchemaEditorClipboard"
                  data-content={JSON.encode!(@schema)}
                >
                  <span>Copy to Clipboard</span>
                </button>
              </div>
              <div class="jse-preview-content">
                <pre class="jse-code-block"><code><%= PrettyPrinter.format(@schema) %></code></pre>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
