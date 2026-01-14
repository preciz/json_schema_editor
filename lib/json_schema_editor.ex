defmodule JSONSchemaEditor do
  use Phoenix.LiveComponent
  alias JSONSchemaEditor.SchemaUtils
  alias JSONSchemaEditor.Styles
  alias JSONSchemaEditor.Validator

  @types ["string", "number", "integer", "boolean", "object", "array"]
  @logic_types ["anyOf", "oneOf", "allOf"]

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:ui_state, fn -> %{} end)
      |> assign_new(:schema, fn -> %{"type" => "object", "properties" => %{}} end)
      |> assign(:types, @types)
      |> assign(:logic_types, @logic_types)
      |> validate_and_assign_errors()

    {:ok, socket}
  end

  defp validate_and_assign_errors(socket) do
    errors = Validator.validate_schema(socket.assigns.schema)
    assign(socket, :validation_errors, errors)
  end

  def handle_event("change_type", %{"path" => path_json, "type" => new_type}, socket) do
    socket =
      update_schema(socket, path_json, fn node ->
        # Clean up existing conflicting keys
        base_node = Map.drop(node, ["type", "properties", "required", "items", "anyOf", "oneOf", "allOf"])

        case new_type do
          "object" -> Map.put(base_node, "type", "object") |> Map.put("properties", %{})
          "array" -> Map.put(base_node, "type", "array") |> Map.put("items", %{"type" => "string"})
          logic when logic in @logic_types -> Map.put(base_node, logic, [%{"type" => "string"}])
          _ -> Map.put(base_node, "type", new_type)
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
    {:noreply, update_node_field(socket, path_json, "title", title)}
  end

  def handle_event("change_description", %{"path" => path_json, "value" => description}, socket) do
    {:noreply, update_node_field(socket, path_json, "description", description)}
  end

  def handle_event("toggle_ui", %{"path" => path_json, "type" => type}, socket) do
    ui_state = socket.assigns.ui_state
    key = "#{type}:#{path_json}"
    new_expanded = !Map.get(ui_state, key, false)
    ui_state = Map.put(ui_state, key, new_expanded)

    {:noreply, assign(socket, :ui_state, ui_state)}
  end

  def handle_event(
        "update_constraint",
        %{"path" => path_json, "field" => field, "value" => value},
        socket
      ) do
    casted_value = cast_constraint_value(field, value)

    socket =
      update_schema(socket, path_json, fn node ->
        if casted_value in [nil, "", false] do
          Map.delete(node, field)
        else
          Map.put(node, field, casted_value)
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
        casted_value = cast_value_by_type(type, value)

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

  def handle_event("remove_logic_branch", %{"path" => path_json, "type" => logic_type, "index" => index}, socket) do
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
    value = String.trim(value)

    update_schema(socket, path_json, fn node ->
      if value == "" do
        Map.delete(node, field)
      else
        Map.put(node, field, value)
      end
    end)
  end

  defp cast_constraint_value(field, value) do
    cond do
      field in [
        "minLength",
        "maxLength",
        "minItems",
        "maxItems",
        "minProperties",
        "maxProperties"
      ] ->
        case Integer.parse(value) do
          {int, _} -> int
          :error -> nil
        end

      field in ["minimum", "maximum", "multipleOf"] ->
        case Float.parse(value) do
          {float, _} -> float
          :error -> nil
        end

      field == "uniqueItems" ->
        value == "true"

      true ->
        value
    end
  end

  defp cast_value_by_type("integer", value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp cast_value_by_type("number", value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  defp cast_value_by_type("boolean", value) do
    value == "true"
  end

  defp cast_value_by_type(_type, value), do: value

  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  defp badge(assigns) do
    ~H"""
    <span class={["jse-badge", @class]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr(:label, :string, required: true)
  attr(:field, :string, required: true)
  attr(:value, :any, required: true)
  attr(:path, :list, required: true)
  attr(:type, :string, default: "text")
  attr(:step, :string, default: nil)
  attr(:validation_errors, :map, required: true)
  attr(:myself, :any, required: true)

  defp constraint_input(assigns) do
    error_key = "#{JSON.encode!(assigns.path)}:#{assigns.field}"
    assigns = assign(assigns, :error, Map.get(assigns.validation_errors, error_key))

    ~H"""
    <div class="jse-constraint-field">
      <label class="jse-constraint-label"><%= @label %></label>
      <input
        type={@type}
        step={@step}
        value={@value}
        class={["jse-constraint-input", @error && "jse-input-error"]}
        phx-blur="update_constraint"
        phx-value-path={JSON.encode!(@path)}
        phx-value-field={@field}
        phx-target={@myself}
      />
      <%= if @error do %>
        <div class="jse-error-message"><%= @error %></div>
      <% end %>
    </div>
    """
  end

  attr(:path, :list, required: true)
  attr(:node, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:myself, :any, required: true)

  defp enum_section(assigns) do
    error_key = "#{JSON.encode!(assigns.path)}:enum"
    assigns = assign(assigns, :error, Map.get(assigns.validation_errors, error_key))

    ~H"""
    <div class="jse-enum-container">
      <div class="jse-header" style="margin-bottom: 0.5rem; padding-bottom: 0.25rem;">
        <div>
          <span class="jse-constraint-label">Enum Values</span>
          <%= if @error do %>
            <div class="jse-error-message" style="display: inline-block; margin-left: 0.5rem;">
              <%= @error %>
            </div>
          <% end %>
        </div>
        <button
          class="jse-btn jse-btn-secondary jse-btn-sm"
          style="padding: 0.125rem 0.5rem;"
          phx-click="add_enum_value"
          phx-target={@myself}
          phx-value-path={JSON.encode!(@path)}
        >
          <.icon name={:plus} class="jse-icon-xs" /> Add
        </button>
      </div>
      <div class="jse-enum-list">
        <%= for {val, idx} <- Enum.with_index(Map.get(@node, "enum", [])) do %>
          <div class="jse-enum-item">
            <input
              type="text"
              value={to_string(val)}
              class="jse-enum-input"
              phx-blur="update_enum_value"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
              phx-value-index={idx}
            />
            <button
              class="jse-btn-icon"
              phx-click="remove_enum_value"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
              phx-value-index={idx}
            >
              <.icon name={:trash} class="jse-icon-xs" />
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:name, :atom, required: true)
  attr(:class, :string, default: nil)

  defp icon(%{name: :save} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class={["jse-icon", @class]}>
      <path fill-rule="evenodd" d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp icon(%{name: :chevron_up} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class={["jse-icon", @class]}>
      <path fill-rule="evenodd" d="M14.77 12.79a.75.75 0 01-1.06-.02L10 8.832 6.29 12.77a.75.75 0 11-1.08-1.04l4.25-4.5a.75.75 0 011.08 0l4.25 4.5a.75.75 0 01-.02 1.06z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp icon(%{name: :chevron_down} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class={["jse-icon", @class]}>
      <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp icon(%{name: :trash} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class={["jse-icon", @class]}>
      <path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp icon(%{name: :plus} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class={["jse-icon", @class]}>
      <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
    </svg>
    """
  end

  defp icon(%{name: :adjustments} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class={["jse-icon", @class]}>
      <path fill-rule="evenodd" d="M2 4.75A.75.75 0 012.75 4h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 4.75zm0 10.5a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75zM2 10a.75.75 0 01.75-.75h7.5a.75.75 0 010 1.5h-7.5A.75.75 0 012 10z" clip-rule="evenodd" />
      <path d="M12.75 8a.75.75 0 01.75.75v2.5a.75.75 0 01-1.5 0v-2.5a.75.75 0 01.75-.75zM7.75 13a.75.75 0 01.75.75v2.5a.75.75 0 01-1.5 0v-2.5a.75.75 0 01.75-.75zM17.75 3a.75.75 0 01.75.75v2.5a.75.75 0 01-1.5 0v-2.5A.75.75 0 0117.75 3z" />
    </svg>
    """
  end

  def render(assigns) do
    assigns =
      assigns
      |> assign(:types, @types)
      |> assign(:logic_types, @logic_types)

    ~H"""
    <div id={@id} class="jse-host">
      <style>
        <%= Styles.styles() %>
      </style>
      <div class="jse-container">
        <div class="jse-header">
          <.badge>Schema Root</.badge>
          <button
            class="jse-btn jse-btn-primary"
            phx-click="save"
            phx-target={@myself}
            disabled={not Enum.empty?(@validation_errors)}
            style={if not Enum.empty?(@validation_errors), do: "opacity: 0.5; cursor: not-allowed;"}
          >
            <span>Save Changes</span>
            <.icon name={:save} />
          </button>
        </div>

        <div class="jse-main-layout">
          <div class="jse-editor-pane">
            <.render_node
              node={@schema}
              path={[]}
              ui_state={@ui_state}
              validation_errors={@validation_errors}
              types={@types}
              logic_types={@logic_types}
              myself={@myself}
            />
          </div>

          <div class="jse-preview-panel">
            <div class="jse-preview-header">
              <span>JSON Schema Preview</span>
              <button
                class="jse-btn-copy"
                onclick={"navigator.clipboard.writeText(this.getAttribute('data-content')).then(() => { 
                  this.classList.add('jse-copied'); 
                  const span = this.querySelector('span');
                  const oldText = span.innerText;
                  span.innerText = 'Copied!';
                  setTimeout(() => { 
                    this.classList.remove('jse-copied'); 
                    span.innerText = oldText;
                  }, 2000); 
                })"}
                data-content={JSON.encode!(@schema)}
              >
                <span>Copy</span>
              </button>
            </div>
            <div class="jse-preview-content">
              <pre class="jse-code-block"><code><%= JSON.encode!(@schema) %></code></pre>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:ui_state, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:types, :list, required: true)
  attr(:logic_types, :list, required: true)
  attr(:myself, :any, required: true)

  defp render_node(assigns) do
    logic_key = Enum.find(assigns.logic_types, &Map.has_key?(assigns.node, &1))

    assigns = assign(assigns, :logic_key, logic_key)

    ~H"""
    <div class="jse-node-container">
      <.node_header
        node={@node}
        path={@path}
        ui_state={@ui_state}
        validation_errors={@validation_errors}
        types={@types}
        logic_types={@logic_types}
        myself={@myself}
      />

      <%= if !Map.get(@ui_state, "collapsed_node:#{JSON.encode!(@path)}", false) do %>
        <%= if Map.get(@ui_state, "expanded_constraints:#{JSON.encode!(@path)}", false) do %>
          <.constraint_grid
            node={@node}
            path={@path}
            validation_errors={@validation_errors}
            myself={@myself}
          />
        <% end %>

        <%= if @logic_key do %>
          <.logic_branches
            node={@node}
            path={@path}
            logic_type={@logic_key}
            ui_state={@ui_state}
            validation_errors={@validation_errors}
            types={@types}
            logic_types={@logic_types}
            myself={@myself}
          />
        <% else %>
          <%= case Map.get(@node, "type") do %>
            <% "array" -> %>
              <.array_items
                node={@node}
                path={@path}
                ui_state={@ui_state}
                validation_errors={@validation_errors}
                types={@types}
                logic_types={@logic_types}
                myself={@myself}
              />
            <% "object" -> %>
              <.object_properties
                node={@node}
                path={@path}
                ui_state={@ui_state}
                validation_errors={@validation_errors}
                types={@types}
                logic_types={@logic_types}
                myself={@myself}
              />
            <% _ -> %>
              <%!-- No children --%>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:ui_state, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:types, :list, required: true)
  attr(:logic_types, :list, required: true)
  attr(:myself, :any, required: true)

  defp node_header(assigns) do
    ~H"""
    <div class="jse-node-header">
      <% logic_active = Enum.any?(@logic_types, &Map.has_key?(@node, &1)) %>
      <%= if Map.get(@node, "type") in ["object", "array"] or logic_active do %>
        <button
          class={[
            "jse-btn-icon jse-node-toggle",
            Map.get(@ui_state, "collapsed_node:#{JSON.encode!(@path)}", false) && "jse-collapsed"
          ]}
          phx-click="toggle_ui"
          phx-value-type="collapsed_node"
          phx-target={@myself}
          phx-value-path={JSON.encode!(@path)}
          title="Toggle Collapse"
        >
          <.icon name={:chevron_down} class="jse-icon-xs" />
        </button>
      <% end %>

      <form phx-change="change_type" phx-target={@myself} class="jse-type-form">
        <input type="hidden" name="path" value={JSON.encode!(@path)} />
        <select name="type" class="jse-type-select">
          <optgroup label="Basic Types">
            <%= for type <- @types do %>
              <option value={type} selected={Map.get(@node, "type") == type}>
                <%= String.capitalize(type) %>
              </option>
            <% end %>
          </optgroup>
          <optgroup label="Logic Composition">
            <%= for type <- @logic_types do %>
              <option value={type} selected={Map.has_key?(@node, type)}>
                <%= String.capitalize(type) %>
              </option>
            <% end %>
          </optgroup>
        </select>
      </form>

      <input
        type="text"
        value={Map.get(@node, "title", "")}
        placeholder="Title..."
        class="jse-title-input"
        phx-blur="change_title"
        phx-target={@myself}
        phx-value-path={JSON.encode!(@path)}
      />

      <div class="jse-description-container">
        <%= if Map.get(@ui_state, "expanded_description:#{JSON.encode!(@path)}", false) do %>
          <div class="jse-description-expanded">
            <textarea
              class="jse-description-textarea"
              placeholder="Description..."
              phx-blur="change_description"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
            ><%= Map.get(@node, "description", "") %></textarea>
            <button
              class="jse-btn-icon jse-btn-sm"
              phx-click="toggle_ui"
              phx-value-type="expanded_description"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
              title="Collapse Description"
            >
              <.icon name={:chevron_up} class="jse-icon-sm" />
            </button>
          </div>
        <% else %>
          <div class="jse-description-collapsed">
            <input
              type="text"
              value={Map.get(@node, "description", "")}
              placeholder="Description..."
              class="jse-description-input"
              phx-blur="change_description"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
            />
            <button
              class="jse-btn-icon jse-btn-sm"
              phx-click="toggle_ui"
              phx-value-type="expanded_description"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
              title="Expand Description"
            >
              <.icon name={:chevron_down} class="jse-icon-sm" />
            </button>
          </div>
        <% end %>
      </div>

      <button
        class={[
          "jse-btn-icon jse-btn-toggle-constraints",
          Map.get(@ui_state, "expanded_constraints:#{JSON.encode!(@path)}", false) && "jse-active"
        ]}
        phx-click="toggle_ui"
        phx-value-type="expanded_constraints"
        phx-target={@myself}
        phx-value-path={JSON.encode!(@path)}
        title="Toggle Constraints"
      >
        <.icon name={:adjustments} class="jse-icon-sm" />
      </button>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:myself, :any, required: true)

  defp constraint_grid(assigns) do
    ~H"""
    <div class="jse-constraints-container">
      <div class="jse-constraints-grid">
        <%= case Map.get(@node, "type") do %>
          <% "string" -> %>
            <.constraint_input
              label="Min Length"
              field="minLength"
              value={Map.get(@node, "minLength")}
              path={@path}
              type="number"
              validation_errors={@validation_errors}
              myself={@myself}
            />
            <.constraint_input
              label="Max Length"
              field="maxLength"
              value={Map.get(@node, "maxLength")}
              path={@path}
              type="number"
              validation_errors={@validation_errors}
              myself={@myself}
            />
            <.constraint_input
              label="Pattern"
              field="pattern"
              value={Map.get(@node, "pattern")}
              path={@path}
              validation_errors={@validation_errors}
              myself={@myself}
            />
          <% type when type in ["number", "integer"] -> %>
            <.constraint_input
              label="Minimum"
              field="minimum"
              value={Map.get(@node, "minimum")}
              path={@path}
              type="number"
              step="any"
              validation_errors={@validation_errors}
              myself={@myself}
            />
            <.constraint_input
              label="Maximum"
              field="maximum"
              value={Map.get(@node, "maximum")}
              path={@path}
              type="number"
              step="any"
              validation_errors={@validation_errors}
              myself={@myself}
            />
            <.constraint_input
              label="Multiple Of"
              field="multipleOf"
              value={Map.get(@node, "multipleOf")}
              path={@path}
              type="number"
              step="any"
              validation_errors={@validation_errors}
              myself={@myself}
            />
          <% "array" -> %>
            <.constraint_input
              label="Min Items"
              field="minItems"
              value={Map.get(@node, "minItems")}
              path={@path}
              type="number"
              validation_errors={@validation_errors}
              myself={@myself}
            />
            <.constraint_input
              label="Max Items"
              field="maxItems"
              value={Map.get(@node, "maxItems")}
              path={@path}
              type="number"
              validation_errors={@validation_errors}
              myself={@myself}
            />
            <div class="jse-constraint-field">
              <label class="jse-constraint-label">Unique Items</label>
              <input
                type="checkbox"
                checked={Map.get(@node, "uniqueItems") == true}
                phx-click="update_constraint"
                phx-value-path={JSON.encode!(@path)}
                phx-value-field="uniqueItems"
                phx-value-value={(!Map.get(@node, "uniqueItems", false)) |> to_string()}
                phx-target={@myself}
              />
            </div>
          <% "object" -> %>
            <.constraint_input
              label="Min Props"
              field="minProperties"
              value={Map.get(@node, "minProperties")}
              path={@path}
              type="number"
              validation_errors={@validation_errors}
              myself={@myself}
            />
            <.constraint_input
              label="Max Props"
              field="maxProperties"
              value={Map.get(@node, "maxProperties")}
              path={@path}
              type="number"
              validation_errors={@validation_errors}
              myself={@myself}
            />
          <% _ -> %>
            <span class="jse-constraint-label">No constraints for this type</span>
        <% end %>
        <.enum_section
          node={@node}
          path={@path}
          validation_errors={@validation_errors}
          myself={@myself}
        />
      </div>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:logic_type, :string, required: true)
  attr(:ui_state, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:types, :list, required: true)
  attr(:logic_types, :list, required: true)
  attr(:myself, :any, required: true)

  defp logic_branches(assigns) do
    ~H"""
    <div class="jse-logic-container">
      <div class="jse-logic-header">
        <.badge class="jse-badge-logic"><%= String.capitalize(@logic_type) %> Branches</.badge>
      </div>
      <div class="jse-logic-content">
        <%= for {branch, idx} <- Map.get(@node, @logic_type, []) |> Enum.with_index() do %>
          <div class="jse-logic-branch">
            <div class="jse-logic-branch-header">
              <span class="jse-logic-branch-label">Branch <%= idx + 1 %></span>
              <button
                phx-click="remove_logic_branch"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                phx-value-type={@logic_type}
                phx-value-index={idx}
                class="jse-btn-icon jse-btn-delete"
                title="Remove Branch"
              >
                <.icon name={:trash} class="jse-icon-xs" />
              </button>
            </div>
            <.render_node
              node={branch}
              path={@path ++ [@logic_type, idx]}
              ui_state={@ui_state}
              validation_errors={@validation_errors}
              types={@types}
              logic_types={@logic_types}
              myself={@myself}
            />
          </div>
        <% end %>

        <div class="jse-add-property-container">
          <button
            phx-click="add_logic_branch"
            phx-target={@myself}
            phx-value-path={JSON.encode!(@path)}
            phx-value-type={@logic_type}
            class="jse-btn jse-btn-secondary jse-btn-sm"
          >
            <div class="jse-icon-circle jse-icon-circle-logic">
              <.icon name={:plus} class="jse-icon-xs" />
            </div>
            Add Branch
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:ui_state, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:types, :list, required: true)
  attr(:logic_types, :list, required: true)
  attr(:myself, :any, required: true)

  defp array_items(assigns) do
    ~H"""
    <div class="jse-array-items-container">
      <div class="jse-array-items-header">
        <.badge class="jse-badge-info">Array Items</.badge>
      </div>
      <div class="jse-array-items-content">
        <.render_node
          node={Map.get(@node, "items", %{"type" => "string"})}
          path={@path ++ ["items"]}
          ui_state={@ui_state}
          validation_errors={@validation_errors}
          types={@types}
          logic_types={@logic_types}
          myself={@myself}
        />
      </div>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:ui_state, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:types, :list, required: true)
  attr(:logic_types, :list, required: true)
  attr(:myself, :any, required: true)

  defp object_properties(assigns) do
    ~H"""
    <div class="jse-properties-list">
      <div class="jse-object-controls">
        <label class="jse-strict-toggle" title="Disallow properties not defined below">
          <input
            type="checkbox"
            checked={Map.get(@node, "additionalProperties") == false}
            phx-click="toggle_additional_properties"
            phx-target={@myself}
            phx-value-path={JSON.encode!(@path)}
          />
          <span class="jse-strict-text">Strict Mode (additionalProperties: false)</span>
        </label>
      </div>

      <%= for {key, val} <- Map.get(@node, "properties", %{}) |> Enum.sort_by(fn {k, _v} -> k end) do %>
        <div class="jse-property-item">
          <div class="jse-property-row">
            <button
              phx-click="delete_property"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
              phx-value-key={key}
              class="jse-btn-icon jse-btn-delete"
              title="Delete Property"
            >
              <.icon name={:trash} class="jse-icon-sm" />
            </button>
            <div class="jse-property-content">
              <input
                type="text"
                value={key}
                name="property_name"
                class="jse-property-key-input"
                phx-blur="rename_property"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                phx-value-old_key={key}
              />
              <label class="jse-required-checkbox-label" title="Toggle Required">
                <input
                  type="checkbox"
                  checked={key in Map.get(@node, "required", [])}
                  phx-click="toggle_required"
                  phx-value-path={JSON.encode!(@path)}
                  phx-value-key={key}
                  phx-target={@myself}
                />
                <span class="jse-required-text">Req</span>
              </label>
              <.render_node
                node={val}
                path={@path ++ ["properties", key]}
                ui_state={@ui_state}
                validation_errors={@validation_errors}
                types={@types}
                logic_types={@logic_types}
                myself={@myself}
              />
            </div>
          </div>
        </div>
      <% end %>

      <div class="jse-add-property-container">
        <button
          phx-click="add_property"
          phx-target={@myself}
          phx-value-path={JSON.encode!(@path)}
          class="jse-btn jse-btn-secondary jse-btn-sm"
        >
          <div class="jse-icon-circle">
            <.icon name={:plus} class="jse-icon-xs" />
          </div>
          Add Property
        </button>
      </div>
    </div>
    """
  end
end
