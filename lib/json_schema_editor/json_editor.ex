defmodule JSONSchemaEditor.JSONEditor do
  @moduledoc """
  A Phoenix LiveComponent for visually editing JSON data.

  It provides a tree-based editor for modifying nested JSON structures, with
  support for various data types and real-time JSON Schema validation.

  ## Attributes

    * `id` (required) - A unique identifier for the component instance.
    * `json` (optional) - The initial JSON data to edit. Defaults to `%{}`.
    * `schema` (optional) - A JSON Schema (as a map) to validate the data against.
    * `on_save` (optional) - A 1-arity callback function invoked when the user clicks "Save".
      It receives the current JSON data as a map or list.
    * `class` (optional) - Additional CSS classes to apply to the root container.

  ## Examples

  ### Basic Usage

      <.live_component
        module={JSONSchemaEditor.JSONEditor}
        id="json-editor"
        json={%{"foo" => "bar", "count" => 42}}
      />

  ### With Schema Validation

      <.live_component
        module={JSONSchemaEditor.JSONEditor}
        id="json-editor-with-schema"
        json={@user_data}
        schema={@user_schema}
        on_save={fn updated -> IO.inspect(updated) end}
      />
  """
  use Phoenix.LiveComponent

  alias JSONSchemaEditor.{SimpleValidator, Viewer, Components, SchemaUtils}

  @doc false
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:active_tab, fn -> :editor end)
      |> assign_new(:json, fn -> %{} end)
      |> assign_new(:schema, fn -> nil end)
      |> assign_new(:collapsed_nodes, fn -> MapSet.new() end)
      |> assign_new(:expanded_editor, fn -> nil end)
      |> assign_new(:class, fn -> nil end)
      |> validate_json()

    {:ok, socket}
  end

  defp validate_json(socket) do
    errors =
      if socket.assigns.schema,
        do: SimpleValidator.validate(socket.assigns.schema, socket.assigns.json),
        else: []

    assign(socket, :validation_errors, errors)
  end

  # --- Event Handlers ---

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("save", _, socket) do
    has_errors = not Enum.empty?(socket.assigns[:validation_errors] || [])
    has_schema = not is_nil(socket.assigns[:schema])

    if socket.assigns[:on_save] && not (has_schema and has_errors) do
      socket.assigns.on_save.(socket.assigns.json)
    end

    {:noreply, socket}
  end

  def handle_event("update_value", %{"path" => path, "value" => val, "type" => type}, socket) do
    new_val = SchemaUtils.cast_type(val, type)
    handle_json_update(socket, path, fn _ -> new_val end)
  end

  def handle_event("update_key", %{"path" => path, "old_key" => old, "value" => new}, socket) do
    handle_json_update(socket, path, fn obj ->
      val = Map.get(obj, old)
      obj |> Map.delete(old) |> Map.put(new, val)
    end)
  end

  def handle_event("add_property", %{"path" => path}, socket) do
    handle_json_update(socket, path, fn obj ->
      key = SchemaUtils.generate_unique_key(obj, "newKey")
      Map.put(obj, key, nil)
    end)
  end

  def handle_event("delete_property", %{"path" => path, "key" => key}, socket) do
    handle_json_update(socket, path, &Map.delete(&1, key))
  end

  def handle_event("add_item", %{"path" => path}, socket) do
    handle_json_update(socket, path, &(&1 ++ [nil]))
  end

  def handle_event("delete_item", %{"path" => path, "index" => index}, socket) do
    idx = String.to_integer(index)
    handle_json_update(socket, path, &List.delete_at(&1, idx))
  end

  def handle_event("change_value_type", %{"path" => path, "value" => type}, socket) do
    handle_json_update(socket, path, fn current ->
      SchemaUtils.cast_type(current, type)
    end)
  end

  def handle_event("toggle_collapse", %{"path" => path_json}, socket) do
    path = JSON.decode!(path_json)
    path_id = Enum.join(path, "/")

    new_collapsed =
      if MapSet.member?(socket.assigns.collapsed_nodes, path_id),
        do: MapSet.delete(socket.assigns.collapsed_nodes, path_id),
        else: MapSet.put(socket.assigns.collapsed_nodes, path_id)

    {:noreply, assign(socket, :collapsed_nodes, new_collapsed)}
  end

  # --- Expanded Editor ---

  def handle_event("edit_large_value", %{"path" => path_json}, socket) do
    path = JSON.decode!(path_json)
    value = SchemaUtils.get_in_path(socket.assigns.json, path)
    {:noreply, assign(socket, :expanded_editor, %{path: path, value: value})}
  end

  def handle_event("close_expanded_editor", _, socket) do
    {:noreply, assign(socket, :expanded_editor, nil)}
  end

  def handle_event("save_expanded_value", %{"value" => new_value}, socket) do
    path = socket.assigns.expanded_editor.path

    socket
    |> assign(:expanded_editor, nil)
    |> handle_json_update(path, fn _ -> new_value end)
  end

  # --- Private Helpers ---

  defp handle_json_update(socket, path, func) do
    new_json = SchemaUtils.update_in_path(socket.assigns.json, path, func)
    {:noreply, socket |> assign(:json, new_json) |> validate_json()}
  end

  defp path_to_id(path) do
    "node-" <> (JSON.encode!(path) |> :erlang.md5() |> Base.encode16(case: :lower))
  end

  defp is_collapsed?(collapsed, path), do: MapSet.member?(collapsed, Enum.join(path, "/"))

  defp get_row_errors(errors, path) do
    path_str = format_error_path(path)
    for {p, msg} <- errors, p == path_str, do: msg
  end

  defp format_error_path(path) do
    path
    |> Enum.map(fn
      i when is_integer(i) -> "[#{i}]"
      k -> ".#{k}"
    end)
    |> Enum.join("")
    |> String.trim_leading(".")
    |> case do
      "" -> "(root)"
      str -> str
    end
  end

  # --- Render ---

  def render(assigns) do
    ~H"""
    <div id={@id} class={["jse-host", @class]}>
      <div class="jse-container">
        <div class="jse-header">
          <div class="jse-tabs">
            <button
              class={["jse-tab-btn", @active_tab == :editor && "active"]}
              phx-click="switch_tab"
              phx-value-tab="editor"
              phx-target={@myself}
            >
              Editor
            </button>
            <button
              class={["jse-tab-btn", @active_tab == :preview && "active"]}
              phx-click="switch_tab"
              phx-value-tab="preview"
              phx-target={@myself}
            >
              Preview
            </button>
            <%= if @schema do %>
              <button
                class={["jse-tab-btn", @active_tab == :schema && "active"]}
                phx-click="switch_tab"
                phx-value-tab="schema"
                phx-target={@myself}
              >
                Schema
              </button>
            <% end %>
          </div>
          <div class="jse-status">
            <%= if @schema do %>
              <%= if Enum.empty?(@validation_errors) do %>
                <span class="jse-badge-success">Valid</span>
              <% else %>
                <span class="jse-badge-error">Invalid</span>
              <% end %>
            <% end %>
          </div>
          <div class="jse-actions">
            <button
              class="jse-btn jse-btn-primary"
              phx-click="save"
              phx-target={@myself}
              disabled={@schema && not Enum.empty?(@validation_errors)}
            >
              <span>Save</span> <Components.icon name={:save} class="jse-icon-xs" />
            </button>
          </div>
        </div>

        <div class="jse-content-area">
          <%= if @active_tab == :editor do %>
            <div class="jse-editor-pane">
              <.render_json_node
                value={@json}
                path={[]}
                depth={0}
                collapsed_nodes={@collapsed_nodes}
                validation_errors={@validation_errors}
                myself={@myself}
              />
            </div>
          <% end %>

          <%= if @active_tab == :preview do %>
            <div class="jse-preview-panel">
              <div class="jse-preview-header">
                <span>Current JSON</span>
                <button
                  class="jse-btn-copy"
                  id={"#{@id}-copy-btn"}
                  phx-hook="JSONSchemaEditorClipboard"
                  data-content={JSON.encode!(@json)}
                >
                  <span>Copy</span>
                </button>
              </div>
              <div class="jse-preview-content">
                <Viewer.render json={@json} />
              </div>
            </div>
          <% end %>

          <%= if @active_tab == :schema do %>
            <div class="jse-preview-panel">
              <div class="jse-preview-header">
                <span>Schema</span>
              </div>
              <div class="jse-preview-content">
                <Viewer.render json={@schema} />
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @expanded_editor do %>
        <div class="jse-modal-overlay">
          <div class="jse-modal">
            <div class="jse-modal-header">
              <span class="jse-modal-title">Edit Value</span>
              <button class="jse-btn-icon" phx-click="close_expanded_editor" phx-target={@myself}>
                <Components.icon name={:close} class="jse-icon-sm" />
              </button>
            </div>
            <form phx-submit="save_expanded_value" phx-target={@myself}>
              <div class="jse-modal-body">
                <textarea
                  name="value"
                  class="jse-modal-textarea"
                  autofocus
                >{@expanded_editor.value}</textarea>
              </div>
              <div class="jse-modal-footer">
                <button
                  type="button"
                  class="jse-btn jse-btn-secondary"
                  phx-click="close_expanded_editor"
                  phx-target={@myself}
                >
                  Cancel
                </button>
                <button type="submit" class="jse-btn jse-btn-primary">
                  Apply
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_json_node(assigns) do
    type = SchemaUtils.get_type(assigns.value)

    assigns =
      assigns
      |> assign(:type, type)
      |> assign_new(:key, fn -> nil end)
      |> assign_new(:index, fn -> nil end)

    assigns =
      assign(assigns, :row_errors, get_row_errors(assigns.validation_errors, assigns.path))

    ~H"""
    <div class="jse-tree-node" id={path_to_id(@path)}>
      <% is_collapsible = @type in ["object", "array"]
      is_collapsed = is_collapsible and is_collapsed?(@collapsed_nodes, @path)
      has_error = not Enum.empty?(@row_errors) %>

      <div class={["jse-tree-row", has_error && "jse-row-error"]}>
        <%= for _ <- 0..(@depth-1)//1, @depth > 0 do %>
          <span class="jse-indent-guide"></span>
        <% end %>

        <%= if is_collapsible do %>
          <button
            class="jse-tree-toggle"
            phx-click="toggle_collapse"
            phx-value-path={JSON.encode!(@path)}
            phx-target={@myself}
          >
            <Components.icon
              name={if is_collapsed, do: :chevron_right, else: :chevron_down}
              class="jse-icon-xs"
            />
          </button>
        <% else %>
          <span class="jse-tree-toggle placeholder"></span>
        <% end %>

        <%= if @key do %>
          <input
            type="text"
            class="jse-key-input"
            value={@key}
            phx-blur="update_key"
            phx-value-path={JSON.encode!(Enum.drop(@path, -1))}
            phx-value-old_key={@key}
            phx-target={@myself}
          />
          <span class="jse-separator">:</span>
        <% end %>

        <%= if @index != nil do %>
          <span class="jse-key-input" style="pointer-events: none; color: var(--jse-text-tertiary);">
            {@index}
          </span>
          <span class="jse-separator">:</span>
        <% end %>

        <%= if is_collapsible do %>
          <span class="jse-meta">
            {if @type == "object", do: "{}", else: "[]"}
            {if @type == "object", do: "#{map_size(@value)} items", else: "#{length(@value)} items"}
          </span>
        <% else %>
          <.render_value_input
            type={@type}
            value={@value}
            path={@path}
            myself={@myself}
          />
        <% end %>

        <div class="jse-tree-actions">
          <%= if @type == "string" do %>
            <button
              class="jse-action-btn"
              phx-click="edit_large_value"
              phx-value-path={JSON.encode!(@path)}
              phx-target={@myself}
              title="Edit (Multiline)"
            >
              <Components.icon name={:pencil} class="jse-icon-xs" />
            </button>
          <% end %>

          <form phx-change="change_value_type" phx-target={@myself} style="display:inline;">
            <input type="hidden" name="path" value={JSON.encode!(@path)} />
            <select
              name="value"
              class="jse-type-select"
              title="Change Type"
            >
              <%= for t <- ~w(string number boolean object array null) do %>
                <option value={t} selected={t == @type}>{t}</option>
              <% end %>
            </select>
          </form>

          <%= if @type == "object" do %>
            <button
              class="jse-action-btn"
              phx-click="add_property"
              phx-value-path={JSON.encode!(@path)}
              phx-target={@myself}
              title="Add Property"
            >
              <Components.icon name={:plus} class="jse-icon-xs" />
            </button>
          <% end %>

          <%= if @type == "array" do %>
            <button
              class="jse-action-btn"
              phx-click="add_item"
              phx-value-path={JSON.encode!(@path)}
              phx-target={@myself}
              title="Add Item"
            >
              <Components.icon name={:plus} class="jse-icon-xs" />
            </button>
          <% end %>

          <%= if @path != [] do %>
            <button
              class="jse-action-btn delete"
              phx-click={if @key, do: "delete_property", else: "delete_item"}
              phx-value-path={JSON.encode!(Enum.drop(@path, -1))}
              phx-value-key={@key}
              phx-value-index={@index}
              phx-target={@myself}
              title="Delete"
            >
              <Components.icon name={:trash} class="jse-icon-xs" />
            </button>
          <% end %>
        </div>

        <%= if has_error do %>
          <div class="jse-validation-msg">
            <Components.icon name={:close} class="jse-icon-xs" />
            {Enum.join(@row_errors, "; ")}
          </div>
        <% end %>
      </div>

      <%= if is_collapsible and not is_collapsed do %>
        <div class="jse-tree-children">
          <%= if @type == "object" do %>
            <%= for {k, v} <- @value do %>
              <.render_json_node
                value={v}
                path={@path ++ [k]}
                key={k}
                depth={@depth + 1}
                collapsed_nodes={@collapsed_nodes}
                validation_errors={@validation_errors}
                myself={@myself}
              />
            <% end %>
          <% else %>
            <%= for {v, i} <- Enum.with_index(@value) do %>
              <.render_json_node
                value={v}
                path={@path ++ [i]}
                index={i}
                depth={@depth + 1}
                collapsed_nodes={@collapsed_nodes}
                validation_errors={@validation_errors}
                myself={@myself}
              />
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_value_input(assigns) do
    has_newlines = is_binary(assigns.value) and String.contains?(assigns.value, "\n")
    assigns = assign(assigns, :has_newlines, has_newlines)

    assigns =
      assign(assigns, :input_id, "input-" <> path_to_id(assigns.path) <> "-" <> assigns.type)

    ~H"""
    <%= case @type do %>
      <% "string" -> %>
        <span class="jse-val-string">"</span>
        <%= if @has_newlines do %>
          <span
            id={@input_id}
            class="jse-value-input jse-val-string jse-multiline-preview"
            style="cursor: pointer; display: inline-block; min-width: 4rem;"
            phx-click="edit_large_value"
            phx-value-path={JSON.encode!(@path)}
            phx-target={@myself}
            title="Click to edit multiline string"
          >
            {String.replace(@value, "\n", " ")}
          </span>
        <% else %>
          <input
            id={@input_id}
            type="text"
            class="jse-value-input jse-val-string"
            value={@value}
            phx-blur="update_value"
            phx-value-path={JSON.encode!(@path)}
            phx-value-type="string"
            phx-target={@myself}
            title={@value}
          />
        <% end %>
        <span class="jse-val-string">"</span>
      <% "number" -> %>
        <input
          id={@input_id}
          type="number"
          step="any"
          class="jse-value-input jse-val-number"
          value={@value}
          phx-blur="update_value"
          phx-value-path={JSON.encode!(@path)}
          phx-value-type="number"
          phx-target={@myself}
          title={to_string(@value)}
        />
      <% "boolean" -> %>
        <select
          id={@input_id}
          class="jse-value-input jse-val-boolean"
          phx-change="update_value"
          phx-value-path={JSON.encode!(@path)}
          phx-value-type="boolean"
          phx-target={@myself}
          title={to_string(@value)}
        >
          <option value="true" selected={@value == true}>true</option>
          <option value="false" selected={@value == false}>false</option>
        </select>
      <% "null" -> %>
        <span class="jse-val-null" id={@input_id}>null</span>
    <% end %>
    """
  end
end
