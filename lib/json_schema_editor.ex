defmodule JSONSchemaEditor do
  @moduledoc """
  A Phoenix LiveComponent for visually editing JSON Schemas.

  It provides a rich interface for creating and modifying JSON Schemas (Draft 07), supporting
  nested structures, arrays, validation constraints, and logical composition (oneOf, anyOf, allOf).

  ## Attributes

    * `id` (required) - A unique identifier for the component instance.
    * `schema` (required) - The initial JSON Schema map to edit. Defaults to a basic schema if empty.
    * `on_save` (optional) - A 1-arity callback function invoked when the user clicks "Save".
      It receives the current schema as a map.
    * `class` (optional) - Additional CSS classes to apply to the root container.

  ## Usage

      <.live_component
        module={JSONSchemaEditor}
        id="json-editor"
        schema={@my_schema}
        on_save={fn new_schema -> send(self(), {:save_schema, new_schema}) end}
        class="my-custom-theme"
      />
  """
  use Phoenix.LiveComponent

  alias JSONSchemaEditor.{
    SchemaUtils,
    Validator,
    Components,
    SchemaGenerator,
    SimpleValidator,
    UIState,
    SchemaMutator
  }

  @types ~w(string number integer boolean object array null)

  @logic_types ~w(anyOf oneOf allOf)

  @formats ~w(email date-time date time uri uuid ipv4 ipv6 hostname)

  def update(assigns, socket) do
    known_keys = [
      :id,
      :schema,
      :on_save,
      :ui_state,
      :active_tab,
      :myself,
      :class,
      :show_import_modal,
      :import_error,
      :import_mode,
      :test_data_str,
      :test_errors
    ]

    {known_assigns, rest} = Map.split(assigns, known_keys)

    socket =
      socket
      |> assign(known_assigns)
      |> assign(:rest, Map.merge(Map.get(socket.assigns, :rest, %{}), rest))
      |> assign_new(:class, fn -> nil end)
      |> assign_new(:ui_state, fn -> %{} end)
      |> assign_new(:schema, fn -> %{} end)
      |> update(:schema, &Map.put_new(&1, "$schema", "https://json-schema.org/draft-07/schema"))
      |> assign(types: @types, formats: @formats, logic_types: @logic_types)
      |> assign_new(:active_tab, fn -> :editor end)
      |> assign_new(:show_import_modal, fn -> false end)
      |> assign_new(:import_error, fn -> nil end)
      |> assign_new(:import_mode, fn -> :schema end)
      |> assign_new(:history, fn -> [] end)
      |> assign_new(:future, fn -> [] end)
      |> assign_new(:test_data_str, fn -> "{\n  \"example\": \"value\"\n}" end)
      |> assign_new(:test_errors, fn -> [] end)
      |> validate_and_assign_errors()

    {:ok, socket}
  end

  defp validate_and_assign_errors(socket) do
    schema_errors = Validator.validate_schema(socket.assigns.schema)
    socket = assign(socket, :validation_errors, schema_errors)
    validate_test_data(socket)
  end

  defp validate_test_data(socket) do
    case JSON.decode(socket.assigns.test_data_str) do
      {:ok, data} ->
        errors = SimpleValidator.validate(socket.assigns.schema, data)
        status = if errors == [], do: :ok, else: errors
        assign(socket, :test_errors, status)

      {:error, _} ->
        assign(socket, :test_errors, ["Invalid JSON Syntax"])
    end
  end

  defp push_history(socket) do
    socket
    |> update(:history, fn h -> [socket.assigns.schema | Enum.take(h, 49)] end)
    |> assign(:future, [])
  end

  def handle_event("update_test_data", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> assign(:test_data_str, value)
     |> validate_test_data()}
  end

  def handle_event("undo", _, socket) do
    case socket.assigns.history do
      [previous | rest] ->
        socket =
          socket
          |> update(:future, fn f -> [socket.assigns.schema | f] end)
          |> assign(:history, rest)
          |> assign(:schema, previous)
          |> validate_and_assign_errors()

        {:noreply, socket}

      [] ->
        {:noreply, socket}
    end
  end

  def handle_event("redo", _, socket) do
    case socket.assigns.future do
      [next | rest] ->
        socket =
          socket
          |> update(:history, fn h -> [socket.assigns.schema | h] end)
          |> assign(:future, rest)
          |> assign(:schema, next)
          |> validate_and_assign_errors()

        {:noreply, socket}

      [] ->
        {:noreply, socket}
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket),
    do: {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}

  def handle_event("open_import_modal", _, socket),
    do: {:noreply, assign(socket, :show_import_modal, true) |> assign(:import_mode, :schema)}

  def handle_event("close_import_modal", _, socket),
    do: {:noreply, assign(socket, :show_import_modal, false) |> assign(:import_error, nil)}

  def handle_event("set_import_mode", %{"mode" => mode}, socket),
    do: {:noreply, assign(socket, :import_mode, String.to_existing_atom(mode))}

  def handle_event("import_schema", %{"schema_text" => text}, socket) do
    case JSON.decode(text) do
      {:ok, data} ->
        schema =
          if socket.assigns.import_mode == :json do
            SchemaGenerator.generate(data)
          else
            data
          end

        if is_map(schema) do
          socket =
            socket
            |> push_history()
            |> assign(:schema, schema)
            |> assign(:show_import_modal, false)
            |> assign(:import_error, nil)
            |> validate_and_assign_errors()

          {:noreply, socket}
        else
          {:noreply, assign(socket, :import_error, "Invalid schema: Must be a JSON object")}
        end

      {:error, _} ->
        {:noreply, assign(socket, :import_error, "Invalid JSON")}
    end
  end

  def handle_event("save", _, socket) do
    if Enum.empty?(socket.assigns.validation_errors) and socket.assigns[:on_save],
      do: socket.assigns.on_save.(socket.assigns.schema)

    {:noreply, socket}
  end

  # --- Complex Mutations (involve UI State or special logic) ---

  def handle_event("add_property", %{"path" => path}, socket) do
    {:ok, path_list} = JSON.decode(path)
    current_props = SchemaUtils.get_in_path(socket.assigns.schema, path_list) |> Map.get("properties", %{})
    {new_schema, new_key} = SchemaMutator.add_property(socket.assigns.schema, path)

    {:noreply,
     socket
     |> push_history()
     |> assign(:schema, new_schema)
     |> update(:ui_state, &UIState.add_property(&1, path, current_props, new_key))
     |> validate_and_assign_errors()}
  end

  def handle_event("delete_property", %{"path" => path, "key" => key}, socket) do
    {:noreply,
     socket
     |> push_history()
     |> assign(:schema, SchemaMutator.delete_property(socket.assigns.schema, path, key))
     |> update(:ui_state, &UIState.remove_property(&1, path, key))
     |> validate_and_assign_errors()}
  end

  def handle_event("rename_property", %{"path" => path, "old_key" => old, "value" => new}, socket) do
    case SchemaMutator.rename_property(socket.assigns.schema, path, old, new) do
      {:ok, new_schema} ->
        {:ok, path_list} = JSON.decode(path)
        current_props = SchemaUtils.get_in_path(socket.assigns.schema, path_list) |> Map.get("properties", %{})

        {:noreply,
         socket
         |> push_history()
         |> assign(:schema, new_schema)
         |> update(:ui_state, &UIState.rename_property(&1, path, current_props, old, String.trim(new)))
         |> validate_and_assign_errors()}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_ui", %{"path" => p, "type" => t}, socket),
    do: {:noreply, update(socket, :ui_state, &Map.update(&1, "#{t}:#{p}", true, fn v -> !v end))}

  # --- Simple Mutations (Schema update only) ---

  def handle_event(event, params, socket) do
    case get_mutation(event, params) do
      {func, args} ->
        {:noreply,
         socket
         |> push_history()
         |> assign(:schema, apply(SchemaMutator, func, [socket.assigns.schema | args]))
         |> validate_and_assign_errors()}
      nil ->
        {:noreply, socket}
    end
  end

  defp get_mutation("change_type", %{"path" => p, "type" => t}), do: {:change_type, [p, t]}
  defp get_mutation("toggle_required", %{"path" => p, "key" => k}), do: {:toggle_required, [p, k]}
  defp get_mutation("set_default_schema", _), do: {:update_field, ["[]", "$schema", "https://json-schema.org/draft-07/schema"]}
  defp get_mutation("change_schema", %{"value" => v}), do: {:update_field, ["[]", "$schema", v]}
  defp get_mutation("change_format", %{"path" => p, "value" => v}), do: {:update_field, [p, "format", v]}
  defp get_mutation("change_title", %{"path" => p, "value" => v}), do: {:update_field, [p, "title", String.trim(v)]}
  defp get_mutation("change_description", %{"path" => p, "value" => v}), do: {:update_field, [p, "description", String.trim(v)]}
  defp get_mutation("update_constraint", %{"path" => p, "field" => f, "value" => v}), do: {:update_constraint, [p, f, v]}
  defp get_mutation("update_const", %{"path" => p, "value" => v}), do: {:update_const, [p, v]}
  defp get_mutation("toggle_additional_properties", %{"path" => p}), do: {:toggle_additional_properties, [p]}
  defp get_mutation("add_enum_value", %{"path" => p}), do: {:add_enum_value, [p]}
  defp get_mutation("remove_enum_value", %{"path" => p, "index" => i}), do: {:remove_enum_value, [p, i]}
  defp get_mutation("update_enum_value", %{"path" => p, "index" => i, "value" => v}), do: {:update_enum_value, [p, i, v]}
  defp get_mutation("add_logic_branch", %{"path" => p, "type" => t}), do: {:add_logic_branch, [p, t]}
  defp get_mutation("remove_logic_branch", %{"path" => p, "type" => t, "index" => i}), do: {:remove_logic_branch, [p, t, i]}
  defp get_mutation("add_child", %{"path" => p, "key" => k}), do: {:add_child, [p, k]}
  defp get_mutation("remove_child", %{"path" => p, "key" => k}), do: {:remove_child, [p, k]}
  defp get_mutation(_, _), do: nil
  
    def render(assigns) do
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
            <button
              class={["jse-tab-btn", @active_tab == :test && "active"]}
              phx-click="switch_tab"
              phx-value-tab="test"
              phx-target={@myself}
            >
              Test Lab
            </button>
          </div>
          <div class="jse-schema-selector">
            <label for={"#{@id}-schema-uri"}>$schema</label>
            <div class="jse-input-group">
              <input
                type="text"
                id={"#{@id}-schema-uri"}
                value={Map.get(@schema, "$schema")}
                phx-blur="change_schema"
                phx-target={@myself}
                placeholder="Schema URI..."
              />
              <%= if Map.get(@schema, "$schema") in [nil, ""] do %>
                <button
                  class="jse-btn jse-btn-xs jse-btn-secondary jse-default-schema-btn"
                  phx-click="set_default_schema"
                  phx-target={@myself}
                  title="Set default schema"
                >
                  Default
                </button>
              <% end %>
            </div>
          </div>
          <div class="jse-actions">
            <button
              class="jse-btn jse-btn-icon"
              phx-click="undo"
              phx-target={@myself}
              disabled={Enum.empty?(@history)}
              title="Undo"
            >
              <Components.icon name={:undo} />
            </button>
            <button
              class="jse-btn jse-btn-icon"
              phx-click="redo"
              phx-target={@myself}
              disabled={Enum.empty?(@future)}
              title="Redo"
            >
              <Components.icon name={:redo} />
            </button>
            <button
              class="jse-btn jse-btn-secondary"
              phx-click="open_import_modal"
              phx-target={@myself}
            >
              <span>Import</span> <Components.icon name={:import} />
            </button>
            <button
              class="jse-btn jse-btn-primary"
              phx-click="save"
              phx-target={@myself}
              disabled={not Enum.empty?(@validation_errors)}
            >
              <span>Save</span> <Components.icon name={:save} />
            </button>
          </div>
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
                <JSONSchemaEditor.Viewer.render json={@schema} />
              </div>
            </div>
          <% end %>
          <%= if @active_tab == :test do %>
            <div class="jse-test-lab">
              <div class="jse-test-input-section">
                <div class="jse-preview-header">
                  <span>Sample JSON Data</span>
                </div>
                <textarea
                  class="jse-test-textarea"
                  phx-keyup="update_test_data"
                  phx-target={@myself}
                  spellcheck="false"
                >{@test_data_str}</textarea>
              </div>
              <div class="jse-test-results">
                <div class="jse-preview-header">
                  <span>Validation Results</span>
                  <%= if @test_errors == :ok do %>
                    <Components.badge class="jse-badge-success">Valid</Components.badge>
                  <% else %>
                    <Components.badge class="jse-badge-error">Invalid</Components.badge>
                  <% end %>
                </div>
                <div class="jse-test-output">
                  <%= if @test_errors == :ok do %>
                    <div class="jse-test-success-message">
                      <Components.icon name={:check} class="jse-icon-lg" />
                      <span>Data matches the schema!</span>
                    </div>
                  <% else %>
                    <div class="jse-error-list">
                      <%= for error <- @test_errors do %>
                        <div class="jse-error-item">
                          <%= if is_binary(error) do %>
                            {error}
                          <% else %>
                            <span class="jse-error-path">{elem(error, 1)}</span>
                            <span class="jse-error-desc">{elem(error, 0)}</span>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @show_import_modal do %>
        <div class="jse-modal-overlay">
          <div class="jse-modal">
            <div class="jse-modal-header">
              <div class="jse-tabs">
                <button
                  type="button"
                  class={["jse-tab-btn", @import_mode == :schema && "active"]}
                  phx-click="set_import_mode"
                  phx-value-mode="schema"
                  phx-target={@myself}
                >
                  Import Schema
                </button>
                <button
                  type="button"
                  class={["jse-tab-btn", @import_mode == :json && "active"]}
                  phx-click="set_import_mode"
                  phx-value-mode="json"
                  phx-target={@myself}
                >
                  Generate from JSON
                </button>
              </div>
              <button class="jse-btn-icon" phx-click="close_import_modal" phx-target={@myself}>
                <Components.icon name={:close} class="jse-icon-sm" />
              </button>
            </div>
            <form phx-submit="import_schema" phx-target={@myself}>
              <div class="jse-modal-body">
                <%= if @import_error do %>
                  <div class="jse-modal-error">{@import_error}</div>
                <% end %>
                <textarea
                  name="schema_text"
                  class="jse-modal-textarea"
                  placeholder={
                    if @import_mode == :schema,
                      do: "Paste your JSON Schema here...",
                      else: "Paste a JSON object to generate a schema..."
                  }
                  autofocus
                ></textarea>
              </div>
              <div class="jse-modal-footer">
                <button
                  type="button"
                  class="jse-btn jse-btn-secondary"
                  phx-click="close_import_modal"
                  phx-target={@myself}
                >
                  Cancel
                </button>
                <button type="submit" class="jse-btn jse-btn-primary">
                  {if @import_mode == :schema, do: "Import", else: "Generate"}
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end