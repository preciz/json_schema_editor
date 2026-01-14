defmodule JSONSchemaEditor do
  use Phoenix.LiveComponent

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:id, assigns.id)
      |> assign(:on_save, assigns[:on_save])
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

    schema = put_in_path(socket.assigns.schema, path, new_value)
    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("add_property", %{"path" => path_json}, socket) do
    path = JSON.decode!(path_json)
    props_path = path ++ ["properties"]

    current_props = get_in_path(socket.assigns.schema, props_path) || %{}
    new_key = generate_unique_key(current_props, "new_field")
    new_props = Map.put(current_props, new_key, %{"type" => "string"})

    schema = put_in_path(socket.assigns.schema, props_path, new_props)
    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("delete_property", %{"path" => path_json, "key" => key}, socket) do
    path = JSON.decode!(path_json)
    props_path = path ++ ["properties"]

    current_props = get_in_path(socket.assigns.schema, props_path) || %{}
    new_props = Map.delete(current_props, key)

    schema_with_props = put_in_path(socket.assigns.schema, props_path, new_props)

    # Also remove from required list
    object = get_in_path(schema_with_props, path)
    current_required = Map.get(object, "required", [])
    new_required = List.delete(current_required, key)
    new_object = Map.put(object, "required", new_required)

    schema = put_in_path(schema_with_props, path, new_object)

    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("toggle_required", %{"path" => path_json, "key" => key}, socket) do
    path = JSON.decode!(path_json)
    object = get_in_path(socket.assigns.schema, path)
    current_required = Map.get(object, "required", [])

    new_required =
      if key in current_required do
        List.delete(current_required, key)
      else
        current_required ++ [key]
      end

    new_object = Map.put(object, "required", new_required)
    schema = put_in_path(socket.assigns.schema, path, new_object)

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
      props_path = path ++ ["properties"]

      current_props = get_in_path(socket.assigns.schema, props_path) || %{}

      # Check if new key already exists
      if Map.has_key?(current_props, new_key) do
        {:noreply, socket}
      else
        {value, remaining} = Map.pop(current_props, old_key)
        new_props = Map.put(remaining, new_key, value)

        schema_with_props = put_in_path(socket.assigns.schema, props_path, new_props)

        # Update required list
        object = get_in_path(schema_with_props, path)
        current_required = Map.get(object, "required", [])

        new_required =
          Enum.map(current_required, fn k ->
            if k == old_key, do: new_key, else: k
          end)

        new_object = Map.put(object, "required", new_required)
        schema = put_in_path(schema_with_props, path, new_object)

        {:noreply, assign(socket, :schema, schema)}
      end
    end
  end

  def handle_event("change_title", %{"path" => path_json, "value" => title}, socket) do
    path = JSON.decode!(path_json)
    title = String.trim(title)

    node = get_in_path(socket.assigns.schema, path)

    new_node =
      if title == "" do
        Map.delete(node, "title")
      else
        Map.put(node, "title", title)
      end

    schema = put_in_path(socket.assigns.schema, path, new_node)
    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("change_description", %{"path" => path_json, "value" => description}, socket) do
    path = JSON.decode!(path_json)
    description = String.trim(description)

    node = get_in_path(socket.assigns.schema, path)

    new_node =
      if description == "" do
        Map.delete(node, "description")
      else
        Map.put(node, "description", description)
      end

    schema = put_in_path(socket.assigns.schema, path, new_node)
    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("toggle_description", %{"path" => path_json}, socket) do
    path = JSON.decode!(path_json)
    node = get_in_path(socket.assigns.schema, path)

    new_expanded = !Map.get(node, "expanded_description", false)
    new_node = Map.put(node, "expanded_description", new_expanded)

    schema = put_in_path(socket.assigns.schema, path, new_node)
    {:noreply, assign(socket, :schema, schema)}
  end

  def handle_event("save", _params, socket) do
    if socket.assigns[:on_save] do
      socket.assigns.on_save.(socket.assigns.schema)
    end

    {:noreply, socket}
  end

  defp get_in_path(data, []), do: data

  defp get_in_path(data, [key | rest]) when is_map(data),
    do: get_in_path(Map.get(data, key), rest)

  defp get_in_path(_, _), do: nil

  defp put_in_path(_data, [], value), do: value

  defp put_in_path(data, [key | rest], value) when is_map(data) do
    Map.put(data, key, put_in_path(Map.get(data, key, %{}), rest, value))
  end

  defp generate_unique_key(existing_map, base_name, counter \\ 1) do
    key = if counter == 1, do: base_name, else: "#{base_name}_#{counter}"

    if Map.has_key?(existing_map, key) do
      generate_unique_key(existing_map, base_name, counter + 1)
    else
      key
    end
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="json-schema-editor-host">
      <style>
        <%= styles() %>
      </style>
      <div class="editor-container">
        <div class="header">
          <span class="badge">Schema Root</span>
          <button class="btn btn-primary" phx-click="save" phx-target={@myself}>
            <span>Save Changes</span>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="icon">
              <path fill-rule="evenodd" d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>

        <.render_node
          node={@schema}
          path={[]}
          myself={@myself}
        />
      </div>
    </div>
    """
  end

  defp render_node(assigns) do
    ~H"""

      <div class="node-container">

        <div class="node-header">

          <form phx-change="change_type" phx-target={@myself} class="type-form">

            <input type="hidden" name="path" value={JSON.encode!(@path)} />

            <select name="type" class="type-select">

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

                      class="title-input"

                      phx-blur="change_title"

                      phx-target={@myself}

                      phx-value-path={JSON.encode!(@path)}

                    />

            

                    <div class="description-container">
          <%= if Map.get(@node, "expanded_description", false) do %>
            <div class="description-expanded">
              <textarea
                class="description-textarea"
                placeholder="Description..."
                phx-blur="change_description"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
              ><%= Map.get(@node, "description", "") %></textarea>
              <button
                class="btn-icon btn-sm"
                phx-click="toggle_description"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                title="Collapse Description"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="icon-sm">
                  <path fill-rule="evenodd" d="M14.77 12.79a.75.75 0 01-1.06-.02L10 8.832 6.29 12.77a.75.75 0 11-1.08-1.04l4.25-4.5a.75.75 0 011.08 0l4.25 4.5a.75.75 0 01-.02 1.06z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          <% else %>
            <div class="description-collapsed">
              <input
                type="text"
                value={Map.get(@node, "description", "")}
                placeholder="Description..."
                class="description-input"
                phx-blur="change_description"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
              />
              <button
                class="btn-icon btn-sm"
                phx-click="toggle_description"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                title="Expand Description"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="icon-sm">
                   <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <%= if Map.get(@node, "type") == "array" do %>
        <div class="array-items-container">
          <div class="array-items-header">
            <span class="badge badge-info">Array Items</span>
          </div>
          <div class="array-items-content">
            <.render_node
              node={Map.get(@node, "items", %{"type" => "string"})}
              path={@path ++ ["items"]}
              myself={@myself}
            />
          </div>
        </div>
      <% end %>

      <%= if Map.get(@node, "type") == "object" do %>
        <div class="properties-list">
          <%= for {key, val} <- Map.get(@node, "properties", %{}) |> Enum.sort_by(fn {k, _v} -> k end) do %>
            <div class="property-item">
              <div class="property-row">
                <button
                  phx-click="delete_property"
                  phx-target={@myself}
                  phx-value-path={JSON.encode!(@path)}
                  phx-value-key={key}
                  class="btn-icon btn-delete"
                  title="Delete Property"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="icon-sm">
                    <path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clip-rule="evenodd" />
                  </svg>
                </button>
                                <div class="property-content">
                                  <input
                                    type="text"
                                    value={key}
                                    name="property_name"
                                    class="property-key-input"
                                    phx-blur="rename_property"
                                    phx-target={@myself}
                                    phx-value-path={JSON.encode!(@path)}
                                    phx-value-old_key={key}
                                  />
                                  <label class="required-checkbox-label" title="Toggle Required">
                                    <input
                                      type="checkbox"
                                      checked={key in Map.get(@node, "required", [])}
                                      phx-click="toggle_required"
                                      phx-value-path={JSON.encode!(@path)}
                                      phx-value-key={key}
                                      phx-target={@myself}
                                    />
                                    <span class="required-text">Req</span>
                                  </label>
                                  <.render_node node={val} path={@path ++ ["properties", key]} myself={@myself} />
                                </div>              </div>
            </div>
          <% end %>

          <div class="add-property-container">
            <button
              phx-click="add_property"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
              class="btn btn-secondary btn-sm"
            >
              <div class="icon-circle">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="icon-xs">
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

  defp styles do
    """
    .json-schema-editor-host {
      display: block;
      font-family: system-ui, -apple-system, sans-serif;
      --primary-color: #4f46e5;
      --primary-hover: #4338ca;
      --bg-color: #ffffff;
      --text-color: #1f2937;
      --border-color: #e5e7eb;
      --secondary-bg: #f9fafb;
    }

    @media (prefers-color-scheme: dark) {
      .json-schema-editor-host {
        --bg-color: #1e293b;
        --text-color: #f3f4f6;
        --border-color: #374151;
        --secondary-bg: #0f172a;
      }
    }

    .editor-container {
      background-color: var(--bg-color);
      color: var(--text-color);
      border: 1px solid var(--border-color);
      border-radius: 0.75rem;
      padding: 1.5rem;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
      transition: all 0.3s;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
      padding-bottom: 1rem;
      border-bottom: 1px solid var(--border-color);
    }

    .badge {
      padding: 0.25rem 0.625rem;
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      border-radius: 9999px;
      background-color: #f3e8ff;
      color: #7e22ce;
      border: 1px solid rgba(168, 85, 247, 0.2);
    }

    .badge-info {
      background-color: #e0f2fe;
      color: #0369a1;
      border: 1px solid rgba(14, 165, 233, 0.2);
    }

    .btn {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      font-size: 0.875rem;
      font-weight: 600;
      border-radius: 0.5rem;
      border: none;
      cursor: pointer;
      transition: all 0.2s;
    }

    .btn-primary {
      background-color: var(--primary-color);
      color: white;
      box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
    }

    .btn-primary:hover {
      background-color: var(--primary-hover);
    }

    .btn-secondary {
      color: var(--primary-color);
      background-color: transparent;
    }

    .btn-secondary:hover {
      background-color: #eef2ff;
    }

    .icon {
      width: 1rem;
      height: 1rem;
      opacity: 0.75;
    }

    .node-container {
      margin-left: 1rem;
      margin-top: 0.5rem;
      border-left: 2px solid var(--border-color);
      padding-left: 1rem;
    }

    .node-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .type-select {
      display: block;
      width: 9rem;
      border-radius: 0.5rem;
      border: 1px solid var(--border-color);
      padding: 0.375rem 0.75rem;
      background-color: transparent;
      color: inherit;
      font-size: 0.875rem;
      cursor: pointer;
    }

    .type-select:focus {
      outline: 2px solid var(--primary-color);
      border-color: transparent;
    }

    .title-input {
      width: 8rem;
      font-size: 0.8125rem;
      font-weight: 600;
      padding: 0.375rem 0.75rem;
      border: 1px solid var(--border-color);
      border-radius: 0.5rem;
      background-color: transparent;
      color: inherit;
      transition: border-color 0.2s;
    }

    .title-input:hover, .title-input:focus {
      border-color: var(--primary-color);
    }

    .title-input:focus {
      outline: none;
    }

    .description-container {
      flex: 1;
      min-width: 200px;
    }

    .description-collapsed, .description-expanded {
      display: flex;
      gap: 0.5rem;
      align-items: flex-start;
    }

    .description-input {
      flex: 1;
      font-size: 0.8125rem;
      padding: 0.375rem 0.75rem;
      border: 1px solid var(--border-color);
      border-radius: 0.5rem;
      background-color: transparent;
      color: inherit;
      opacity: 0.6;
      transition: opacity 0.2s, border-color 0.2s;
    }

    .description-textarea {
      flex: 1;
      font-family: inherit;
      font-size: 0.8125rem;
      padding: 0.5rem 0.75rem;
      border: 1px solid var(--border-color);
      border-radius: 0.5rem;
      background-color: var(--bg-color);
      color: inherit;
      min-height: 4rem;
      resize: vertical;
    }

    .description-textarea:focus {
      outline: 2px solid var(--primary-color);
      border-color: transparent;
    }

    .description-input:hover, .description-input:focus {
      opacity: 1;
      border-color: var(--primary-color);
    }

    .description-input:focus {
      outline: none;
      opacity: 1;
    }

    .array-items-container {
      margin-top: 0.75rem;
      padding: 1rem;
      background-color: var(--secondary-bg);
      border-radius: 0.75rem;
      border: 1px dashed var(--border-color);
    }

    .array-items-header {
      margin-bottom: 0.75rem;
    }

    .properties-list {
      margin-top: 0.5rem;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }

    .property-row {
      display: flex;
      gap: 0.5rem;
      align-items: center;
    }

    .property-content {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .property-key {
      font-weight: 600;
      font-size: 0.875rem;
      min-width: 3rem;
    }

    .property-key-input {
      font-weight: 600;
      font-size: 0.875rem;
      min-width: 5rem;
      max-width: 10rem;
      padding: 0.25rem 0.5rem;
      border: 1px solid transparent;
      border-radius: 0.375rem;
      background: transparent;
      color: inherit;
      font-family: inherit;
    }

    .property-key-input:hover {
      border-color: var(--border-color);
      background-color: var(--secondary-bg);
    }

    .property-key-input:focus {
      outline: none;
      border-color: var(--primary-color);
      background-color: var(--bg-color);
    }

    .btn-icon {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      padding: 0.25rem;
      color: #9ca3af;
      background: transparent;
      border: none;
      border-radius: 9999px;
      cursor: pointer;
    }

    .btn-delete:hover {
      color: #dc2626;
      background-color: #fef2f2;
    }

    .icon-sm {
      width: 1rem;
      height: 1rem;
    }

    .icon-xs {
      width: 0.875rem;
      height: 0.875rem;
    }

    .icon-circle {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 1.25rem;
      height: 1.25rem;
      border-radius: 9999px;
      background-color: #e0e7ff;
      color: var(--primary-color);
    }

    .group:hover .btn-delete {
      opacity: 1;
    }

    .type-form {
      display: inline-block;
    }

    .required-checkbox-label {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      font-size: 0.75rem;
      color: #6b7280;
      cursor: pointer;
      user-select: none;
      margin-right: 0.5rem;
    }

    .required-checkbox-label:hover {
      color: var(--text-color);
    }

    .required-text {
      font-weight: 600;
      font-size: 0.7rem;
      text-transform: uppercase;
    }
    """
  end
end
