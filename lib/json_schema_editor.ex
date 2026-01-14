defmodule JSONSchemaEditor do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="schema-editor-root font-sans">
      <div class="p-6 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 transition-all duration-300">
        <div class="flex items-center justify-between mb-6 pb-4 border-b border-slate-100 dark:border-slate-700">
          <div class="flex items-center gap-2">
            <span class="px-2.5 py-1 text-xs font-bold tracking-wider uppercase rounded-full bg-purple-100 text-purple-700 dark:bg-purple-900/50 dark:text-purple-300 ring-1 ring-purple-500/20">
              Schema Root
            </span>
          </div>
          <button
            phx-click="save"
            phx-target={@myself}
            class="group flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-indigo-600 rounded-lg shadow-md hover:bg-indigo-500 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all active:scale-95"
          >
            <span>Save Changes</span>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4 opacity-75 group-hover:opacity-100">
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
    <div class="ml-4 mt-2 border-l-2 border-gray-200 dark:border-gray-700 pl-4">
      <div class="flex items-center gap-2">
        <span class="font-mono text-sm font-medium text-gray-700 dark:text-gray-300">
          <%= type_label(@node) %>
        </span>
        
        <!-- Type Selector -->
        <form phx-change="change_type" phx-target={@myself} class="inline-block">
          <input type="hidden" name="path" value={JSON.encode!(@path)} />
          <select 
            name="type"
            class="block w-36 rounded-lg border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-slate-900 dark:text-white dark:ring-slate-600 dark:focus:ring-indigo-500 shadow-sm transition-shadow cursor-pointer hover:ring-gray-400 dark:hover:ring-slate-500"
          >
            <%= for type <- ["string", "number", "integer", "boolean", "object", "array"] do %>
              <option value={type} selected={Map.get(@node, "type") == type}><%= String.capitalize(type) %></option>
            <% end %>
          </select>
        </form>
      </div>

      <!-- Object Properties -->
      <%= if Map.get(@node, "type") == "object" do %>
        <div class="mt-2 space-y-2">
          <%= for {key, val} <- Map.get(@node, "properties", %{}) do %>
            <div class="group relative">
              <div class="flex items-center gap-2">
                <button 
                  phx-click="delete_property"
                  phx-target={@myself}
                  phx-value-path={JSON.encode!(@path)}
                  phx-value-key={key}
                  class="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors opacity-0 group-hover:opacity-100"
                  title="Delete Property"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
                    <path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clip-rule="evenodd" />
                  </svg>
                </button>
                <div class="flex items-center gap-2 flex-1">
                  <span class="text-sm font-semibold text-gray-600 dark:text-gray-400 min-w-[3rem]"><%= key %>:</span>
                  <.render_node node={val} path={@path ++ ["properties", key]} myself={@myself} />
                </div>
              </div>
            </div>
          <% end %>
          
          <div class="mt-3 pl-2">
            <button 
              phx-click="add_property" 
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
              class="group flex items-center gap-2 text-xs font-semibold text-indigo-600 hover:text-indigo-500 dark:text-indigo-400 dark:hover:text-indigo-300 transition-colors px-3 py-2 rounded-md hover:bg-indigo-50 dark:hover:bg-indigo-900/20"
            >
              <div class="flex items-center justify-center w-5 h-5 rounded-full bg-indigo-100 text-indigo-600 group-hover:bg-indigo-200 dark:bg-indigo-900/50 dark:text-indigo-300 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-3.5 h-3.5">
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

  defp type_label(node) do
    Map.get(node, "type", "unknown")
  end

  def handle_event("change_type", params, socket) do
    # Handle cases where params might be slightly different
    %{"type" => new_type, "path" => path_json} = params
    
    path = JSON.decode!(path_json)
    new_schema = update_schema_at(socket.assigns.schema, path, fn node -> 
      Map.put(node, "type", new_type)
      |> handle_type_change(new_type)
    end)
    
    {:noreply, assign(socket, schema: new_schema)}
  end

  def handle_event("delete_property", %{"path" => path_json, "key" => key}, socket) do
    path = JSON.decode!(path_json)
    new_schema = update_schema_at(socket.assigns.schema, path, fn node ->
      props = Map.get(node, "properties", %{})
      new_props = Map.delete(props, key)
      Map.put(node, "properties", new_props)
    end)

    {:noreply, assign(socket, schema: new_schema)}
  end

  def handle_event("add_property", %{"path" => path_json}, socket) do
    path = JSON.decode!(path_json)
    # Simple prompt workaround? No, for now just add a default "new_field"
    # In a real app we'd use a modal or inline input for the name.
    # For MVP let's just add "new_prop_TIMESTAMP"
    prop_name = "prop_#{System.system_time(:second)}"
    
    new_schema = update_schema_at(socket.assigns.schema, path, fn node ->
      props = Map.get(node, "properties", %{})
      new_props = Map.put(props, prop_name, %{"type" => "string"})
      Map.put(node, "properties", new_props)
    end)

    {:noreply, assign(socket, schema: new_schema)}
  end

  def handle_event("save", _, socket) do
    socket.assigns.on_save.(socket.assigns.schema)
    {:noreply, socket}
  end

  defp update_schema_at(schema, [], func), do: func.(schema)
  defp update_schema_at(schema, [head | tail], func) do
    Map.update!(schema, head, fn val -> update_schema_at(val, tail, func) end)
  end

  defp handle_type_change(node, "object") do
    if Map.has_key?(node, "properties"), do: node, else: Map.put(node, "properties", %{})
  end
  defp handle_type_change(node, _), do: node

end
