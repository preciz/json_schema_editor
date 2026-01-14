defmodule JSONSchemaEditor.Styles do
  @moduledoc """
  CSS styles for the JSON Schema Editor.
  """

  def styles do
    """
    .jse-host {
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
      .jse-host {
        --bg-color: #1e293b;
        --text-color: #f3f4f6;
        --border-color: #374151;
        --secondary-bg: #0f172a;
      }
    }

    .jse-container {
      background-color: var(--bg-color);
      color: var(--text-color);
      border: 1px solid var(--border-color);
      border-radius: 0.75rem;
      padding: 1.5rem;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
      transition: all 0.3s;
    }

    .jse-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
      padding-bottom: 1rem;
      border-bottom: 1px solid var(--border-color);
    }

    .jse-badge {
      padding: 0.25rem 0.625rem;
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      border-radius: 9999px;
      background-color: #f3e8ff;
      color: #7e22ce;
      border: 1px solid rgba(168, 85, 247, 0.2);
    }

    .jse-badge-info {
      background-color: #e0f2fe;
      color: #0369a1;
      border: 1px solid rgba(14, 165, 233, 0.2);
    }

    .jse-badge-logic {
      background-color: #fef2f2;
      color: #991b1b;
      border: 1px solid rgba(239, 68, 68, 0.2);
    }

    .jse-logic-container {
      margin-top: 0.75rem;
      padding: 1rem;
      background-color: var(--secondary-bg);
      border-radius: 0.75rem;
      border: 1px solid var(--border-color);
    }

    .jse-logic-header {
      margin-bottom: 0.75rem;
    }

    .jse-logic-content {
      display: flex;
      flex-direction: column;
      gap: 1rem;
    }

    .jse-logic-branch {
      padding: 0.75rem;
      background-color: var(--bg-color);
      border-radius: 0.5rem;
      border: 1px solid var(--border-color);
    }

    .jse-logic-branch-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 0.5rem;
      padding-bottom: 0.25rem;
      border-bottom: 1px dashed var(--border-color);
    }

    .jse-logic-branch-label {
      font-size: 0.75rem;
      font-weight: 700;
      color: #6b7280;
    }

    .jse-icon-circle-logic {
      background-color: #fee2e2;
      color: #ef4444;
    }

    .jse-btn {
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

    .jse-btn-primary {
      background-color: var(--primary-color);
      color: white;
      box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
    }

    .jse-btn-primary:hover {
      background-color: var(--primary-hover);
    }

    .jse-btn-secondary {
      color: var(--primary-color);
      background-color: transparent;
    }

    .jse-btn-secondary:hover {
      background-color: #eef2ff;
    }

    .jse-icon {
      width: 1rem;
      height: 1rem;
      opacity: 0.75;
    }

    .jse-node-container {
      margin-left: 1rem;
      margin-top: 0.5rem;
      border-left: 2px solid var(--border-color);
      padding-left: 1rem;
    }

    .jse-node-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .jse-type-select {
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

    .jse-type-select:focus {
      outline: 2px solid var(--primary-color);
      border-color: transparent;
    }

    .jse-title-input {
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

    .jse-title-input:hover, .jse-title-input:focus {
      border-color: var(--primary-color);
    }

    .jse-title-input:focus {
      outline: none;
    }

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
      font-size: 0.8125rem;
      padding: 0.375rem 0.75rem;
      border: 1px solid var(--border-color);
      border-radius: 0.5rem;
      background-color: transparent;
      color: inherit;
      opacity: 0.6;
      transition: opacity 0.2s, border-color 0.2s;
    }

    .jse-description-textarea {
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

    .jse-description-textarea:focus {
      outline: 2px solid var(--primary-color);
      border-color: transparent;
    }

    .jse-description-input:hover, .jse-description-input:focus {
      opacity: 1;
      border-color: var(--primary-color);
    }

    .jse-description-input:focus {
      outline: none;
      opacity: 1;
    }

    .jse-array-items-container {
      margin-top: 0.75rem;
      padding: 1rem;
      background-color: var(--secondary-bg);
      border-radius: 0.75rem;
      border: 1px dashed var(--border-color);
    }

    .jse-array-items-header {
      margin-bottom: 0.75rem;
    }

    .jse-properties-list {
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
      margin-top: 0.75rem;
      padding-left: 1.25rem;
      border-left: 2px solid var(--border-color);
    }

    .jse-object-controls {
      margin-bottom: 0.5rem;
      padding: 0.25rem 0.5rem;
      background-color: #f9fafb;
      border-radius: 0.375rem;
      border: 1px dashed #d1d5db;
    }

    .jse-strict-toggle {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      cursor: pointer;
      font-size: 0.75rem;
      color: #374151;
      font-weight: 500;
    }

    .jse-strict-text {
      user-select: none;
    }

    .jse-property-item {

    .jse-property-row {
      display: flex;
      gap: 0.5rem;
      align-items: center;
    }

    .jse-property-content {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .jse-property-key {
      font-weight: 600;
      font-size: 0.875rem;
      min-width: 3rem;
    }

    .jse-property-key-input {
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

    .jse-property-key-input:hover {
      border-color: var(--border-color);
      background-color: var(--secondary-bg);
    }

    .jse-property-key-input:focus {
      outline: none;
      border-color: var(--primary-color);
      background-color: var(--bg-color);
    }

    .jse-btn-icon {
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

    .jse-btn-delete:hover {
      color: #dc2626;
      background-color: #fef2f2;
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
      width: 1.25rem;
      height: 1.25rem;
      border-radius: 9999px;
      background-color: #e0e7ff;
      color: var(--primary-color);
    }

    .jse-type-form {
      display: inline-block;
    }

    .jse-required-checkbox-label {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      font-size: 0.75rem;
      color: #6b7280;
      cursor: pointer;
      user-select: none;
      margin-right: 0.5rem;
    }

    .jse-required-checkbox-label:hover {
      color: var(--text-color);
    }

    .jse-required-text {
      font-weight: 600;
      font-size: 0.7rem;
      text-transform: uppercase;
    }

    .jse-constraints-container {
      margin-top: 0.5rem;
      margin-bottom: 0.5rem;
      padding: 0.75rem;
      background-color: var(--secondary-bg);
      border-radius: 0.5rem;
      border: 1px solid var(--border-color);
    }

    .jse-constraints-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
      gap: 0.75rem;
    }

    .jse-constraint-field {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }

    .jse-constraint-label {
      font-size: 0.7rem;
      font-weight: 700;
      color: #6b7280;
      text-transform: uppercase;
    }

    .jse-constraint-input {
      font-size: 0.8125rem;
      padding: 0.25rem 0.5rem;
      border: 1px solid var(--border-color);
      border-radius: 0.375rem;
      background-color: var(--bg-color);
      color: inherit;
    }

    .jse-constraint-input:focus {
      outline: 2px solid var(--primary-color);
      border-color: transparent;
    }

    .jse-btn-toggle-constraints {
      color: #9ca3af;
      transition: color 0.2s;
    }

    .jse-btn-toggle-constraints.jse-active {
      color: var(--primary-color);
    }

    .jse-node-toggle {
      margin-left: -1.25rem;
      width: 1.25rem;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #9ca3af;
      cursor: pointer;
      transition: transform 0.2s;
    }

    .jse-node-toggle:hover {
      color: var(--primary-color);
    }

    .jse-node-toggle.jse-collapsed {
      transform: rotate(-90deg);
    }

    .jse-input-error {
      border-color: #dc2626 !important;
    }

    .jse-error-message {
      font-size: 0.65rem;
      color: #dc2626;
      font-weight: 600;
      margin-top: 0.125rem;
    }

    .jse-enum-container {
      grid-column: 1 / -1;
      margin-top: 0.5rem;
      padding-top: 0.75rem;
      border-top: 1px dashed var(--border-color);
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
      padding: 0.25rem 0.5rem;
      background-color: var(--bg-color);
      border: 1px solid var(--border-color);
      border-radius: 0.375rem;
    }

    .jse-enum-input {
      font-size: 0.75rem;
      border: none;
      background: transparent;
      color: inherit;
      padding: 0;
      width: 4rem;
      min-width: 2rem;
    }

    .jse-enum-input:focus {
      outline: none;
    }
    """
  end
end
