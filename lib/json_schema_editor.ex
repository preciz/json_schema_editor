defmodule JSONSchemaEditor do
  use Phoenix.LiveComponent
  alias JSONSchemaEditor.SchemaUtils
  alias JSONSchemaEditor.Styles

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:id, assigns.id)
      |> assign(:on_save, assigns[:on_save])
      |> assign_new(:ui_state, fn -> %{} end)
      |> assign_new(:schema, fn ->
        assigns[:schema] || %{"type" => "object", "properties" => %{}}
      end)

    {:ok, socket}
  end

  def handle_event("change_type", %{"path" => path_json, "type" => new_type}, socket) do
    path = JSON.decode!(path_json)

    new_value =
      case new_type do
        "object" -> %{"type" => "object", "properties" => %{}}
        "array" -> %{"type" => "array", "items" => %{"type" => "string"}}
        _ -> %{"type" => new_type}
      end

    schema = SchemaUtils.put_in_path(socket.assigns.schema, path, new_value)
    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("add_property", %{"path" => path_json}, socket) do
    path = JSON.decode!(path_json)

    schema =
      SchemaUtils.update_in_path(socket.assigns.schema, path ++ ["properties"], fn props ->
        props = props || %{}
        new_key = SchemaUtils.generate_unique_key(props, "new_field")
        Map.put(props, new_key, %{"type" => "string"})
      end)

    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("delete_property", %{"path" => path_json, "key" => key}, socket) do
    path = JSON.decode!(path_json)

    schema =
      SchemaUtils.update_in_path(socket.assigns.schema, path, fn node ->
        new_props = Map.delete(Map.get(node, "properties", %{}), key)
        new_required = List.delete(Map.get(node, "required", []), key)

        node
        |> Map.put("properties", new_props)
        |> Map.put("required", new_required)
      end)

    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("toggle_required", %{"path" => path_json, "key" => key}, socket) do
    path = JSON.decode!(path_json)

    schema =
      SchemaUtils.update_in_path(socket.assigns.schema, path, fn node ->
        current_required = Map.get(node, "required", [])

        new_required =
          if key in current_required do
            List.delete(current_required, key)
          else
            current_required ++ [key]
          end

        Map.put(node, "required", new_required)
      end)

    {:noreply, assign(socket, :schema, schema)}
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
      path = JSON.decode!(path_json)

      schema =
        SchemaUtils.update_in_path(socket.assigns.schema, path, fn node ->
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

      {:noreply, assign(socket, :schema, schema)}
    end
  end

  def handle_event("change_title", %{"path" => path_json, "value" => title}, socket) do
    path = JSON.decode!(path_json)
    title = String.trim(title)

    schema =
      SchemaUtils.update_in_path(socket.assigns.schema, path, fn node ->
        if title == "" do
          Map.delete(node, "title")
        else
          Map.put(node, "title", title)
        end
      end)

    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("change_description", %{"path" => path_json, "value" => description}, socket) do
    path = JSON.decode!(path_json)
    description = String.trim(description)

    schema =
      SchemaUtils.update_in_path(socket.assigns.schema, path, fn node ->
        if description == "" do
          Map.delete(node, "description")
        else
          Map.put(node, "description", description)
        end
      end)

    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("toggle_description", %{"path" => path_json}, socket) do
    ui_state = socket.assigns.ui_state
    new_expanded = !Map.get(ui_state, "expanded_description:#{path_json}", false)
    ui_state = Map.put(ui_state, "expanded_description:#{path_json}", new_expanded)

    {:noreply, assign(socket, :ui_state, ui_state)}
  end

  def handle_event("save", _params, socket) do
    if socket.assigns[:on_save] do
      socket.assigns.on_save.(socket.assigns.schema)
    end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="jse-host">
      <style>
        <%= Styles.styles() %>
      </style>
      <div class="jse-container">
        <div class="jse-header">
          <span class="jse-badge">Schema Root</span>
          <button class="jse-btn jse-btn-primary" phx-click="save" phx-target={@myself}>
            <span>Save Changes</span>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="jse-icon">
              <path fill-rule="evenodd" d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>

        <.render_node
          node={@schema}
          path={[]}
          ui_state={@ui_state}
          myself={@myself}
        />
      </div>
    </div>
    """
  end

  defp render_node(assigns) do
    ~H"""
    <div class="jse-node-container">
      <div class="jse-node-header">
        <form phx-change="change_type" phx-target={@myself} class="jse-type-form">
          <input type="hidden" name="path" value={JSON.encode!(@path)} />
          <select name="type" class="jse-type-select">
            <%= for type <- ["string", "number", "integer", "boolean", "object", "array"] do %>
              <option value={type} selected={Map.get(@node, "type") == type}>
                <%= String.capitalize(type) %>
              </option>
            <% end %>
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
                phx-click="toggle_description"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                title="Collapse Description"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="jse-icon-sm">
                  <path fill-rule="evenodd" d="M14.77 12.79a.75.75 0 01-1.06-.02L10 8.832 6.29 12.77a.75.75 0 11-1.08-1.04l4.25-4.5a.75.75 0 011.08 0l4.25 4.5a.75.75 0 01-.02 1.06z" clip-rule="evenodd" />
                </svg>
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
                phx-click="toggle_description"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                title="Expand Description"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="jse-icon-sm">
                   <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <%= if Map.get(@node, "type") == "array" do %>
        <div class="jse-array-items-container">
          <div class="jse-array-items-header">
            <span class="jse-badge jse-badge-info">Array Items</span>
          </div>
          <div class="jse-array-items-content">
            <.render_node
              node={Map.get(@node, "items", %{"type" => "string"})}
              path={@path ++ ["items"]}
              ui_state={@ui_state}
              myself={@myself}
            />
          </div>
        </div>
      <% end %>

      <%= if Map.get(@node, "type") == "object" do %>
        <div class="jse-properties-list">
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
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="jse-icon-sm">
                    <path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clip-rule="evenodd" />
                  </svg>
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
                                        myself={@myself}
                                      />
                                    </div>              </div>
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
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="jse-icon-xs">
                  <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                </svg>
              </div>
              Add Property
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
