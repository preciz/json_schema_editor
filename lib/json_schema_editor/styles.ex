defmodule JSONSchemaEditor.Styles do
  @moduledoc """
  CSS styles for the JSON Schema Editor.
  """

  def styles do
    """
    .jse-host {
      display: block;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
      
      /* Light Mode Palette */
      --jse-bg: #ffffff;
      --jse-bg-secondary: #f3f4f6; /* Gray 100 */
      --jse-bg-tertiary: #e5e7eb;  /* Gray 200 */
      
      --jse-text-primary: #111827; /* Gray 900 */
      --jse-text-secondary: #4b5563; /* Gray 600 */
      --jse-text-tertiary: #9ca3af; /* Gray 400 */
      
      --jse-border: #e5e7eb; /* Gray 200 */
      --jse-border-focus: #6366f1; /* Indigo 500 */
      
      --jse-primary: #4f46e5; /* Indigo 600 */
      --jse-primary-hover: #4338ca; /* Indigo 700 */
      --jse-primary-text: #ffffff;
      
      --jse-danger: #dc2626; /* Red 600 */
      --jse-danger-bg: #fef2f2; /* Red 50 */
      --jse-danger-border: #fecaca; /* Red 200 */
      
      --jse-success: #059669; /* Emerald 600 */
      --jse-success-bg: #ecfdf5; /* Emerald 50 */

      --jse-radius: 0.375rem;
      --jse-shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
      --jse-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }

    @media (prefers-color-scheme: dark) {
      .jse-host {
        /* Dark Mode Palette */
        --jse-bg: #111827; /* Gray 900 */
        --jse-bg-secondary: #1f2937; /* Gray 800 */
        --jse-bg-tertiary: #374151;  /* Gray 700 */
        
        --jse-text-primary: #f9fafb; /* Gray 50 */
        --jse-text-secondary: #d1d5db; /* Gray 300 */
        --jse-text-tertiary: #9ca3af; /* Gray 400 */
        
        --jse-border: #374151; /* Gray 700 */
        --jse-border-focus: #818cf8; /* Indigo 400 */
        
        --jse-primary: #6366f1; /* Indigo 500 */
        --jse-primary-hover: #818cf8; /* Indigo 400 */
        
        --jse-danger: #ef4444; /* Red 500 */
        --jse-danger-bg: #450a0a; /* Red 950 */
        --jse-danger-border: #7f1d1d; /* Red 900 */
        
        --jse-success: #10b981; /* Emerald 500 */
        --jse-success-bg: #064e3b; /* Emerald 900 */
      }
    }

    /* Layout & Containers */
    .jse-container {
      display: flex;
      flex-direction: column;
      gap: 1rem;
      color: var(--jse-text-primary);
      background-color: var(--jse-bg);
      min-height: 100vh;
    }

    /* Header & Tabs */
    .jse-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0.75rem 0;
      border-bottom: 1px solid var(--jse-border);
    }

    .jse-title-badge-container {
      display: flex;
      align-items: center;
    }

    .jse-badge {
      display: inline-flex;
      align-items: center;
      padding: 0.25rem 0.75rem;
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      border-radius: 9999px;
      background-color: var(--jse-bg-secondary);
      color: var(--jse-text-secondary);
      border: 1px solid var(--jse-border);
    }

    .jse-badge-info {
      background-color: var(--jse-bg-tertiary);
      color: var(--jse-text-primary);
    }

    .jse-badge-logic {
      background-color: var(--jse-danger-bg);
      color: var(--jse-danger);
      border-color: var(--jse-danger-border);
    }

    .jse-tabs {
      display: flex;
      gap: 0.25rem;
      background-color: var(--jse-bg-secondary);
      padding: 0.25rem;
      border-radius: var(--jse-radius);
      border: 1px solid var(--jse-border);
    }

    .jse-tab-btn {
      padding: 0.375rem 0.75rem;
      font-size: 0.875rem;
      font-weight: 500;
      border-radius: calc(var(--jse-radius) - 2px);
      border: none;
      background: transparent;
      color: var(--jse-text-secondary);
      cursor: pointer;
      transition: all 0.2s;
    }

    .jse-tab-btn:hover {
      color: var(--jse-text-primary);
    }

    .jse-tab-btn.active {
      background-color: var(--jse-bg);
      color: var(--jse-primary);
      box-shadow: var(--jse-shadow-sm);
    }

    /* Buttons */
    .jse-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      font-size: 0.875rem;
      font-weight: 600;
      border-radius: var(--jse-radius);
      border: 1px solid transparent;
      cursor: pointer;
      transition: all 0.2s;
      white-space: nowrap;
    }

    .jse-btn-sm {
      padding: 0.25rem 0.5rem;
      font-size: 0.75rem;
    }

    .jse-btn-primary {
      background-color: var(--jse-primary);
      color: var(--jse-primary-text);
      box-shadow: var(--jse-shadow-sm);
    }

    .jse-btn-primary:hover {
      background-color: var(--jse-primary-hover);
    }

    .jse-btn-primary:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    .jse-btn-secondary {
      background-color: transparent;
      color: var(--jse-text-secondary);
      border: 1px dashed var(--jse-border);
    }

    .jse-btn-secondary:hover {
      background-color: var(--jse-bg-secondary);
      border-color: var(--jse-text-tertiary);
      color: var(--jse-text-primary);
    }

    .jse-btn-icon {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 2rem;
      height: 2rem;
      padding: 0;
      color: var(--jse-text-tertiary);
      background: transparent;
      border: none;
      border-radius: var(--jse-radius);
      cursor: pointer;
      transition: color 0.2s;
    }

    .jse-btn-icon:hover {
      color: var(--jse-text-primary);
      background-color: var(--jse-bg-secondary);
    }

    .jse-btn-delete:hover {
      color: var(--jse-danger);
      background-color: var(--jse-danger-bg);
    }

    /* Node Structure */
    .jse-node-container {
      margin-left: 1rem;
      padding-left: 1rem;
      border-left: 2px solid var(--jse-border);
      position: relative;
    }

    .jse-node-container:hover > .jse-node-header .jse-title-input {
      border-color: var(--jse-border);
    }
    
    .jse-node-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
      padding: 0.5rem 0;
    }

    .jse-node-toggle {
      position: absolute;
      left: -1rem;
      width: 1rem;
      height: 1rem;
      transform: translateX(-50%);
      background-color: var(--jse-bg);
      border: 1px solid var(--jse-border);
      border-radius: 50%;
      color: var(--jse-text-tertiary);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      z-index: 10;
    }

    .jse-node-toggle:hover {
      color: var(--jse-primary);
      border-color: var(--jse-primary);
    }
    
    .jse-node-toggle.jse-collapsed {
       transform: translateX(-50%) rotate(-90deg);
    }

    /* Inputs */
    .jse-type-select {
      background-color: var(--jse-bg-secondary);
      border: 1px solid transparent;
      border-radius: var(--jse-radius);
      padding: 0.375rem 0.75rem;
      font-size: 0.875rem;
      color: var(--jse-text-primary);
      cursor: pointer;
    }

    .jse-type-select:hover {
      background-color: var(--jse-bg-tertiary);
    }
    
    .jse-type-select:focus {
      outline: none;
      box-shadow: 0 0 0 2px var(--jse-primary);
    }

    .jse-title-input {
      background: transparent;
      border: 1px solid transparent;
      border-radius: var(--jse-radius);
      padding: 0.375rem 0.5rem;
      font-size: 0.875rem;
      font-weight: 600;
      color: var(--jse-text-primary);
      width: 12rem;
      transition: border-color 0.2s;
    }

    .jse-title-input:hover, .jse-title-input:focus {
      border-color: var(--jse-border);
      background-color: var(--jse-bg);
    }
    
    .jse-title-input:focus {
      border-color: var(--jse-border-focus);
      outline: none;
    }

    /* Description */
    .jse-description-container {
      flex: 1;
      min-width: 200px;
    }

    .jse-description-collapsed, .jse-description-expanded {
      display: flex;
      gap: 0.5rem;
      align-items: flex-start;
    }

    .jse-description-input {
      flex: 1;
      background: transparent;
      border: 1px solid transparent;
      border-radius: var(--jse-radius);
      padding: 0.375rem 0.5rem;
      font-size: 0.875rem;
      color: var(--jse-text-secondary);
      transition: all 0.2s;
    }

    .jse-description-input:hover, .jse-description-input:focus {
      border-color: var(--jse-border);
      color: var(--jse-text-primary);
    }
    
    .jse-description-input:focus {
      border-color: var(--jse-border-focus);
      outline: none;
    }

    .jse-description-textarea {
      flex: 1;
      width: 100%;
      min-height: 4rem;
      background-color: var(--jse-bg);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 0.5rem;
      font-family: inherit;
      font-size: 0.875rem;
      color: var(--jse-text-primary);
      resize: vertical;
    }

    .jse-description-textarea:focus {
      outline: none;
      border-color: var(--jse-border-focus);
    }

    /* Constraints Grid */
    .jse-constraints-container {
      background-color: var(--jse-bg-secondary);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 1rem;
      margin-bottom: 1rem;
    }

    .jse-constraints-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
      gap: 1rem;
    }

    .jse-constraint-field {
      display: flex;
      flex-direction: column;
      gap: 0.375rem;
    }

    .jse-constraint-label {
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      color: var(--jse-text-tertiary);
    }

    .jse-constraint-input {
      background-color: var(--jse-bg);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 0.375rem 0.5rem;
      font-size: 0.875rem;
      color: var(--jse-text-primary);
      width: 100%;
    }

    .jse-constraint-input:focus {
      outline: none;
      border-color: var(--jse-border-focus);
    }

    .jse-input-error {
      border-color: var(--jse-danger);
    }

    .jse-error-message {
      font-size: 0.75rem;
      color: var(--jse-danger);
    }
    
    .jse-btn-toggle-constraints {
       color: var(--jse-text-tertiary);
    }
    
    .jse-btn-toggle-constraints.jse-active {
      color: var(--jse-primary);
      background-color: var(--jse-bg-secondary);
    }

    /* Enums */
    .jse-enum-container {
      grid-column: 1 / -1;
      padding-top: 1rem;
      margin-top: 0.5rem;
      border-top: 1px dashed var(--jse-border);
    }

    .jse-enum-list {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      margin-top: 0.5rem;
    }

    .jse-enum-item {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      background-color: var(--jse-bg);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 0.25rem 0.5rem;
    }

    .jse-enum-input {
      border: none;
      background: transparent;
      color: var(--jse-text-primary);
      font-size: 0.875rem;
      width: auto;
      min-width: 3rem;
    }
    
    .jse-enum-input:focus {
      outline: none;
    }

    /* Object Properties */
    .jse-properties-list {
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
    }

    .jse-object-controls {
      padding: 0.5rem;
      background-color: var(--jse-bg-secondary);
      border-radius: var(--jse-radius);
      margin-bottom: 0.5rem;
    }

    .jse-strict-toggle {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      font-size: 0.875rem;
      color: var(--jse-text-secondary);
      cursor: pointer;
    }

    .jse-property-item {
      background-color: var(--jse-bg);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 0.75rem;
      position: relative;
    }

    .jse-property-row {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }

    .jse-property-content {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }

    .jse-property-key-input {
      background: transparent;
      border: 1px solid transparent;
      border-radius: var(--jse-radius);
      padding: 0.25rem 0.5rem;
      font-size: 0.875rem;
      font-weight: 700;
      color: var(--jse-text-primary);
      transition: all 0.2s;
    }

    .jse-property-key-input:hover {
      background-color: var(--jse-bg-secondary);
    }

    .jse-property-key-input:focus {
      outline: none;
      background-color: var(--jse-bg);
      border-color: var(--jse-border-focus);
    }
    
    .jse-required-checkbox-label {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      font-size: 0.75rem;
      font-weight: 600;
      color: var(--jse-text-tertiary);
      cursor: pointer;
      text-transform: uppercase;
    }
    
    .jse-required-checkbox-label:hover {
      color: var(--jse-text-primary);
    }

    /* Array & Logic Items */
    .jse-array-items-container, .jse-logic-container {
      background-color: var(--jse-bg-secondary);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 1rem;
      margin-top: 1rem;
    }
    
    .jse-logic-header, .jse-array-items-header {
      margin-bottom: 1rem;
    }
    
    .jse-logic-content {
      display: flex;
      flex-direction: column;
      gap: 1rem;
    }
    
    .jse-logic-branch {
      background-color: var(--jse-bg);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 1rem;
    }
    
    .jse-logic-branch-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-bottom: 0.5rem;
      border-bottom: 1px dashed var(--jse-border);
      margin-bottom: 0.5rem;
    }
    
    .jse-logic-branch-label {
      font-size: 0.75rem;
      font-weight: 700;
      color: var(--jse-text-tertiary);
      text-transform: uppercase;
    }

    /* Preview Panel */
    .jse-preview-panel {
      background-color: var(--jse-bg-secondary);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      overflow: hidden;
    }

    .jse-preview-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0.75rem 1rem;
      background-color: var(--jse-bg-tertiary);
      border-bottom: 1px solid var(--jse-border);
      font-size: 0.875rem;
      font-weight: 600;
      color: var(--jse-text-primary);
    }

    .jse-preview-content {
      padding: 1rem;
      overflow: auto;
      max-height: 80vh;
    }
    
    .jse-code-block {
      margin: 0;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      font-size: 0.875rem;
      color: var(--jse-text-primary);
      white-space: pre-wrap;
    }

    .jse-btn-copy {
      background-color: var(--jse-bg);
      border: 1px solid var(--jse-border);
      border-radius: var(--jse-radius);
      padding: 0.25rem 0.5rem;
      font-size: 0.75rem;
      font-weight: 500;
      color: var(--jse-text-secondary);
      cursor: pointer;
      transition: all 0.2s;
    }

    .jse-btn-copy:hover {
      background-color: var(--jse-bg-secondary);
      color: var(--jse-text-primary);
    }
    
    .jse-btn-copy.jse-copied {
      background-color: var(--jse-success);
      border-color: var(--jse-success);
      color: #ffffff;
    }

    /* Utilities */
    .jse-icon {
      width: 1.25rem;
      height: 1.25rem;
    }
    
    .jse-icon-sm {
      width: 1rem;
      height: 1rem;
    }
    
    .jse-icon-xs {
      width: 0.875rem;
      height: 0.875rem;
    }
    
    .jse-icon-circle {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 1.5rem;
      height: 1.5rem;
      border-radius: 50%;
      background-color: var(--jse-bg-tertiary);
      color: var(--jse-text-secondary);
    }
    
    .jse-icon-circle-logic {
      background-color: var(--jse-danger-bg);
      color: var(--jse-danger);
    }

    .jse-add-property-container {
      margin-top: 0.5rem;
      display: flex;
      justify-content: center;
    }
    """
  end
end