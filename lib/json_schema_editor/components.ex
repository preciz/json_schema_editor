defmodule JSONSchemaEditor.Components do
  @moduledoc false
  use Phoenix.Component

  attr(:name, :atom, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 20 20"
      fill="currentColor"
      class={["jse-icon", @class]}
      {@rest}
    >
      {svg_path(@name)}
    </svg>
    """
  end

  defp svg_path(name) do
    assigns = %{}

    case name do
      :check ->
        ~H(<path
  fill-rule="evenodd"
  d="M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z"
  clip-rule="evenodd"
/>)

      :save ->
        ~H(<path
  fill-rule="evenodd"
  d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
  clip-rule="evenodd"
/>)

      :chevron_up ->
        ~H(<path
  fill-rule="evenodd"
  d="M14.77 12.79a.75.75 0 01-1.06-.02L10 8.832 6.29 12.77a.75.75 0 11-1.08-1.04l4.25-4.5a.75.75 0 011.08 0l4.25 4.5a.75.75 0 01-.02 1.06z"
  clip-rule="evenodd"
/>)

      :chevron_right ->
        ~H(<path
  fill-rule="evenodd"
  d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
  clip-rule="evenodd"
/>)

      :chevron_down ->
        ~H(<path
  fill-rule="evenodd"
  d="M5.23 7.21a.75.75 0 011.06.02L10 10.94l3.71-3.71a.75.75 0 111.06 1.06l-4.25 4.25a.75.75 0 01-1.06 0L5.21 8.27a.75.75 0 01.02-1.06z"
  clip-rule="evenodd"
/>)

      :trash ->
        ~H(<path
  fill-rule="evenodd"
  d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z"
  clip-rule="evenodd"
/>)

      :plus ->
        ~H(<path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />)

      :adjustments ->
        ~H(<g fill-rule="evenodd" clip-rule="evenodd">
  <path d="M2 4.75A.75.75 0 012.75 4h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 4.75zm0 10.5a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75a.75.75 0 01-.75-.75zM2 10a.75.75 0 01.75-.75h7.5a.75.75 0 010 1.5h-7.5A.75.75 0 012 10z" /><path d="M12.75 8a.75.75 0 01.75.75v2.5a.75.75 0 01-1.5 0v-2.5a.75.75 0 01.75-.75zM7.75 13a.75.75 0 01.75.75v2.5a.75.75 0 01-1.5 0v-2.5a.75.75 0 01.75-.75zM17.75 3a.75.75 0 01.75.75v2.5a.75.75 0 01-1.5 0v-2.5A.75.75 0 0117.75 3z" />
</g>)

      :import ->
        ~H(<path
  fill-rule="evenodd"
  d="M4.5 3.75a.75.75 0 0 1 .75-.75h9.5a.75.75 0 0 1 .75.75v6a.75.75 0 0 1-1.5 0V4.5h-8v11h3.75a.75.75 0 0 1 0 1.5H4.5a.75.75 0 0 1-.75-.75v-11.5Zm12.03 10.22a.75.75 0 0 1 0 1.06l-2.5 2.5a.75.75 0 0 1-1.06-1.06l1.22-1.22H10.5a.75.75 0 0 1 0-1.5h3.69l-1.22-1.22a.75.75 0 1 1 1.06-1.06l2.5 2.5Z"
  clip-rule="evenodd"
/>)

      :close ->
        ~H(<path
  fill-rule="evenodd"
  d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
  clip-rule="evenodd"
/>)

      :undo ->
        ~H(<path d="M12.5 5a.75.75 0 0 0-1.28-.53l-5 5a.75.75 0 0 0 0 1.06l5 5a.75.75 0 0 0 1.28-.53V11.5h2.25a3.75 3.75 0 0 1 3.75 3.75v1a.75.75 0 0 0 1.5 0v-1a5.25 5.25 0 0 0-5.25-5.25h-2.25V5Z" />)

      :redo ->
        ~H(<path d="M7.5 5a.75.75 0 0 1 1.28-.53l5 5a.75.75 0 0 1 0 1.06l-5 5a.75.75 0 0 1-1.28-.53V11.5h-2.25a3.75 3.75 0 0 0-3.75 3.75v1a.75.75 0 0 1-1.5 0v-1a5.25 5.25 0 0 1 5.25-5.25h2.25V5Z" />)
    end
  end

  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span class={["jse-badge", @class]} {@rest}>{render_slot(@inner_block)}</span>
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
      <label class="jse-constraint-label">{@label}</label>
      <input
        type={@type}
        step={@step}
        value={@value}
        class={[
          "jse-constraint-input",
          @error && "jse-input-error",
          @type == "number" && "jse-input-number",
          @type == "text" && "jse-input-string"
        ]}
        phx-blur="update_constraint"
        phx-value-path={JSON.encode!(@path)}
        phx-value-field={@field}
        phx-target={@myself}
      />
      <%= if @error do %>
        <div class="jse-error-message">{@error}</div>
      <% end %>
    </div>
    """
  end

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:type, :string, default: "text")
  attr(:step, :string, default: nil)
  attr(:myself, :any, required: true)

  defp const_input(assigns) do
    ~H"""
    <div class="jse-constraint-field">
      <label class="jse-constraint-label">Const</label>
      <input
        type={@type}
        step={@step}
        value={Map.get(@node, "const")}
        class={[
          "jse-constraint-input",
          @type == "number" && "jse-input-number",
          @type == "text" && "jse-input-string"
        ]}
        phx-blur="update_const"
        phx-value-path={JSON.encode!(@path)}
        phx-target={@myself}
      />
    </div>
    """
  end

  defp get_input_class("string"), do: "jse-input-string"
  defp get_input_class("number"), do: "jse-input-number"
  defp get_input_class("integer"), do: "jse-input-number"
  defp get_input_class("boolean"), do: "jse-input-boolean"
  defp get_input_class(_), do: nil

  attr(:path, :list, required: true)
  attr(:node, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:myself, :any, required: true)

  defp enum_section(assigns) do
    error_key = "#{JSON.encode!(assigns.path)}:enum"
    assigns = assign(assigns, :error, Map.get(assigns.validation_errors, error_key))

    ~H"""
    <div class="jse-enum-container">
      <div class="jse-enum-header">
        <div>
          <span class="jse-constraint-label">Enum Values</span>
          <%= if @error do %>
            <div class="jse-error-message jse-enum-error">{@error}</div>
          <% end %>
        </div>
        <button
          class="jse-btn jse-btn-secondary jse-btn-xs"
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
              class={["jse-enum-input", get_input_class(Map.get(@node, "type"))]}
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

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:ui_state, :map, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:types, :list, required: true)
  attr(:logic_types, :list, required: true)
  attr(:formats, :list, default: [])
  attr(:myself, :any, required: true)

  def render_node(assigns) do
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
            formats={@formats}
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
            formats={@formats}
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
                formats={@formats}
                myself={@myself}
              />
              <.array_contains
                node={@node}
                path={@path}
                ui_state={@ui_state}
                validation_errors={@validation_errors}
                types={@types}
                logic_types={@logic_types}
                formats={@formats}
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
                formats={@formats}
                myself={@myself}
              />
            <% _ -> %>
              <%!-- No children --%>
          <% end %>
        <% end %>
        <.conditional_section
          node={@node}
          path={@path}
          ui_state={@ui_state}
          validation_errors={@validation_errors}
          types={@types}
          logic_types={@logic_types}
          formats={@formats}
          myself={@myself}
        />
        <.negation_section
          node={@node}
          path={@path}
          ui_state={@ui_state}
          validation_errors={@validation_errors}
          types={@types}
          logic_types={@logic_types}
          formats={@formats}
          myself={@myself}
        />
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
          <.icon
            name={
              if Map.get(@ui_state, "collapsed_node:#{JSON.encode!(@path)}", false),
                do: :chevron_right,
                else: :chevron_down
            }
            class="jse-icon-xs"
          />
        </button>
      <% end %>
      <form phx-change="change_type" phx-target={@myself} class="jse-type-form">
        <input type="hidden" name="path" value={JSON.encode!(@path)} />
        <select name="type" class="jse-type-select">
          <optgroup label="Basic Types">
            <%= for type <- @types do %>
              <option value={type} selected={Map.get(@node, "type") == type}>
                {String.capitalize(type)}
              </option>
            <% end %>
          </optgroup>
          <optgroup label="Logic Composition">
            <%= for type <- @logic_types do %>
              <option value={type} selected={Map.has_key?(@node, type)}>
                {String.capitalize(type)}
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
        <% expanded = Map.get(@ui_state, "expanded_description:#{JSON.encode!(@path)}", false) %>
        <div class={if expanded, do: "jse-description-expanded", else: "jse-description-collapsed"}>
          <%= if expanded do %>
            <textarea
              class="jse-description-textarea"
              placeholder="Description..."
              phx-blur="change_description"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
            >{Map.get(@node, "description", "")}</textarea>
          <% else %>
            <input
              type="text"
              value={Map.get(@node, "description", "")}
              placeholder="Description..."
              class="jse-description-input"
              phx-blur="change_description"
              phx-target={@myself}
              phx-value-path={JSON.encode!(@path)}
            />
          <% end %>
          <button
            class="jse-btn-icon jse-btn-sm"
            phx-click="toggle_ui"
            phx-value-type="expanded_description"
            phx-target={@myself}
            phx-value-path={JSON.encode!(@path)}
            title={if expanded, do: "Collapse Description", else: "Expand Description"}
          >
            <.icon name={if(expanded, do: :chevron_up, else: :chevron_down)} class="jse-icon-sm" />
          </button>
        </div>
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

  defp constraints_config("string"),
    do: [
      {"Min Length", "minLength", "number"},
      {"Max Length", "maxLength", "number"},
      {"Pattern", "pattern", "text"}
    ]

  defp constraints_config(t) when t in ["number", "integer"],
    do: [
      {"Minimum", "minimum", "number"},
      {"Maximum", "maximum", "number"},
      {"Multiple Of", "multipleOf", "number"}
    ]

  defp constraints_config("array"),
    do: [
      {"Min Items", "minItems", "number"},
      {"Max Items", "maxItems", "number"},
      {"Min Contains", "minContains", "number"},
      {"Max Contains", "maxContains", "number"}
    ]

  defp constraints_config("object"),
    do: [{"Min Props", "minProperties", "number"}, {"Max Props", "maxProperties", "number"}]

  defp constraints_config(_), do: []

  attr(:node, :map, required: true)
  attr(:path, :list, required: true)
  attr(:validation_errors, :map, required: true)
  attr(:formats, :list, default: [])
  attr(:myself, :any, required: true)

  defp constraint_grid(assigns) do
    type = Map.get(assigns.node, "type")
    assigns = assign(assigns, :type, type)

    ~H"""
    <div class="jse-constraints-container">
      <div class="jse-constraints-grid">
        <%= if @type in ["string", "number", "integer"] do %>
          <.const_input
            node={@node}
            path={@path}
            type={if @type == "string", do: "text", else: "number"}
            step="any"
            myself={@myself}
          />
        <% end %>
        <%= for {label, field, type} <- constraints_config(@type) do %>
          <.constraint_input
            label={label}
            field={field}
            value={Map.get(@node, field)}
            path={@path}
            type={type}
            step="any"
            validation_errors={@validation_errors}
            myself={@myself}
          />
        <% end %>
        <%= if @type == "string" do %>
          <div class="jse-constraint-field">
            <label class="jse-constraint-label">Format</label>
            <select class="jse-constraint-input" phx-change="change_format" phx-target={@myself}>
              <input type="hidden" name="path" value={JSON.encode!(@path)} />
              <option value="">None</option>
              <%= for fmt <- @formats do %>
                <option value={fmt} selected={Map.get(@node, "format") == fmt}>{fmt}</option>
              <% end %>
            </select>
          </div>
        <% end %>
        <%= if @type == "boolean" do %>
          <div class="jse-constraint-field">
            <label class="jse-constraint-label">Const</label>
            <select
              class="jse-constraint-input jse-input-boolean"
              phx-change="update_const"
              phx-target={@myself}
            >
              <input type="hidden" name="path" value={JSON.encode!(@path)} />
              <option value="">None</option>
              <%= for val <- [true, false] do %>
                <option value={to_string(val)} selected={Map.get(@node, "const") == val}>
                  {to_string(val)}
                </option>
              <% end %>
            </select>
          </div>
        <% end %>
        <%= if @type == "array" do %>
          <div class="jse-constraint-field">
            <label class="jse-constraint-label">Unique Items</label>
            <input
              type="checkbox"
              checked={Map.get(@node, "uniqueItems") == true}
              phx-click="update_constraint"
              phx-value-path={JSON.encode!(@path)}
              phx-value-field="uniqueItems"
              phx-value-value={!Map.get(@node, "uniqueItems", false) |> to_string()}
              phx-target={@myself}
            />
          </div>
        <% end %>
        <%= if !(@type in ["string", "number", "integer", "boolean", "array", "object", "null"]) do %>
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
  attr(:formats, :list, default: [])
  attr(:myself, :any, required: true)

  defp logic_branches(assigns) do
    ~H"""
    <div class="jse-logic-container">
      <div class="jse-logic-header">
        <.badge class="jse-badge-logic">{String.capitalize(@logic_type)} Branches</.badge>
      </div>
      <div class="jse-logic-content">
        <%= for {branch, idx} <- Map.get(@node, @logic_type, []) |> Enum.with_index() do %>
          <div class="jse-logic-branch">
            <div class="jse-logic-branch-header">
              <span class="jse-logic-branch-label">Branch {idx + 1}</span>
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
              formats={@formats}
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
  attr(:formats, :list, default: [])
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
          formats={@formats}
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
  attr(:formats, :list, default: [])
  attr(:myself, :any, required: true)

  defp array_contains(assigns) do
    ~H"""
    <div class="jse-array-items-container">
      <div class="jse-array-items-header">
        <.badge class="jse-badge-info">Contains</.badge>
        <%= if Map.has_key?(@node, "contains") do %>
          <button
            class="jse-btn-icon jse-btn-delete"
            phx-click="remove_contains"
            phx-target={@myself}
            phx-value-path={JSON.encode!(@path)}
            title="Remove Contains Schema"
          >
            <.icon name={:trash} class="jse-icon-xs" />
          </button>
        <% end %>
      </div>
      <div class="jse-array-items-content">
        <%= if Map.has_key?(@node, "contains") do %>
          <.render_node
            node={Map.get(@node, "contains")}
            path={@path ++ ["contains"]}
            ui_state={@ui_state}
            validation_errors={@validation_errors}
            types={@types}
            logic_types={@logic_types}
            formats={@formats}
            myself={@myself}
          />
        <% else %>
          <button
            class="jse-btn jse-btn-secondary jse-btn-sm"
            phx-click="add_contains"
            phx-target={@myself}
            phx-value-path={JSON.encode!(@path)}
          >
            <.icon name={:plus} class="jse-icon-xs" /> Add Contains Schema
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  alias JSONSchemaEditor.UIState

  attr(:node, :map, required: true)

  attr(:path, :list, required: true)

  attr(:ui_state, :map, required: true)

  attr(:validation_errors, :map, required: true)

  attr(:types, :list, required: true)

  attr(:logic_types, :list, required: true)

  attr(:formats, :list, default: [])

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

      <% props = Map.get(@node, "properties", %{})

      display_keys = UIState.get_ordered_keys(@ui_state, @path, props) %>

      <%= for key <- display_keys do %>
        <% val = Map.get(props, key) %>

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
                formats={@formats}
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
          <div class="jse-icon-circle"><.icon name={:plus} class="jse-icon-xs" /></div>
          Add Property
        </button>
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
  attr(:formats, :list, default: [])
  attr(:myself, :any, required: true)

  defp conditional_section(assigns) do
    ~H"""
    <div class="jse-logic-container">
      <div class="jse-logic-header">
        <.badge class="jse-badge-logic">Conditional Logic</.badge>
        <%= if !Map.has_key?(@node, "if") do %>
          <button
            class="jse-btn jse-btn-secondary jse-btn-xs"
            phx-click="add_if"
            phx-target={@myself}
            phx-value-path={JSON.encode!(@path)}
            title="Add 'if' schema"
          >
            <.icon name={:plus} class="jse-icon-xs" /> Add If
          </button>
        <% end %>
      </div>
      <%= if Map.has_key?(@node, "if") do %>
        <div class="jse-logic-content">
          <div class="jse-logic-branch">
            <div class="jse-logic-branch-header">
              <span class="jse-logic-branch-label">If</span>
              <button
                phx-click="remove_if"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                class="jse-btn-icon jse-btn-delete"
                title="Remove If"
              >
                <.icon name={:trash} class="jse-icon-xs" />
              </button>
            </div>
            <.render_node
              node={Map.get(@node, "if")}
              path={@path ++ ["if"]}
              ui_state={@ui_state}
              validation_errors={@validation_errors}
              types={@types}
              logic_types={@logic_types}
              formats={@formats}
              myself={@myself}
            />
          </div>

          <%= if Map.has_key?(@node, "then") do %>
            <div class="jse-logic-branch">
              <div class="jse-logic-branch-header">
                <span class="jse-logic-branch-label">Then</span>
                <button
                  phx-click="remove_then"
                  phx-target={@myself}
                  phx-value-path={JSON.encode!(@path)}
                  class="jse-btn-icon jse-btn-delete"
                  title="Remove Then"
                >
                  <.icon name={:trash} class="jse-icon-xs" />
                </button>
              </div>
              <.render_node
                node={Map.get(@node, "then")}
                path={@path ++ ["then"]}
                ui_state={@ui_state}
                validation_errors={@validation_errors}
                types={@types}
                logic_types={@logic_types}
                formats={@formats}
                myself={@myself}
              />
            </div>
          <% else %>
            <div class="jse-add-property-container">
              <button
                phx-click="add_then"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                class="jse-btn jse-btn-secondary jse-btn-sm"
              >
                <div class="jse-icon-circle jse-icon-circle-logic"><.icon name={:plus} class="jse-icon-xs" /></div>
                Add Then
              </button>
            </div>
          <% end %>

          <%= if Map.has_key?(@node, "else") do %>
            <div class="jse-logic-branch">
              <div class="jse-logic-branch-header">
                <span class="jse-logic-branch-label">Else</span>
                <button
                  phx-click="remove_else"
                  phx-target={@myself}
                  phx-value-path={JSON.encode!(@path)}
                  class="jse-btn-icon jse-btn-delete"
                  title="Remove Else"
                >
                  <.icon name={:trash} class="jse-icon-xs" />
                </button>
              </div>
              <.render_node
                node={Map.get(@node, "else")}
                path={@path ++ ["else"]}
                ui_state={@ui_state}
                validation_errors={@validation_errors}
                types={@types}
                logic_types={@logic_types}
                formats={@formats}
                myself={@myself}
              />
            </div>
          <% else %>
            <div class="jse-add-property-container">
              <button
                phx-click="add_else"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                class="jse-btn jse-btn-secondary jse-btn-sm"
              >
                <div class="jse-icon-circle jse-icon-circle-logic"><.icon name={:plus} class="jse-icon-xs" /></div>
                Add Else
              </button>
            </div>
          <% end %>
        </div>
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
  attr(:formats, :list, default: [])
  attr(:myself, :any, required: true)

  defp negation_section(assigns) do
    ~H"""
    <div class="jse-logic-container">
      <div class="jse-logic-header">
        <.badge class="jse-badge-logic">Negation (Not)</.badge>
        <%= if !Map.has_key?(@node, "not") do %>
           <button
            class="jse-btn jse-btn-secondary jse-btn-xs"
            phx-click="add_not"
            phx-target={@myself}
            phx-value-path={JSON.encode!(@path)}
            title="Add 'not' schema"
          >
            <.icon name={:plus} class="jse-icon-xs" /> Add Not
          </button>
        <% end %>
      </div>
      <%= if Map.has_key?(@node, "not") do %>
        <div class="jse-logic-content">
          <div class="jse-logic-branch">
             <div class="jse-logic-branch-header">
              <span class="jse-logic-branch-label">Not</span>
              <button
                phx-click="remove_not"
                phx-target={@myself}
                phx-value-path={JSON.encode!(@path)}
                class="jse-btn-icon jse-btn-delete"
                title="Remove Not"
              >
                <.icon name={:trash} class="jse-icon-xs" />
              </button>
            </div>
            <.render_node
              node={Map.get(@node, "not")}
              path={@path ++ ["not"]}
              ui_state={@ui_state}
              validation_errors={@validation_errors}
              types={@types}
              logic_types={@logic_types}
              formats={@formats}
              myself={@myself}
            />
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
