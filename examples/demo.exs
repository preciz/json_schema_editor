Mix.install([
  {:phoenix_playground, "~> 0.1.0"},
  {:json_schema_editor, path: Path.expand("..", __DIR__)}
])

defmodule Demo do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    # Comprehensive demo schema showcasing most important features
    schema = %{
      "$schema" => "https://json-schema.org/draft-07/schema",
      "title" => "User Profile Schema",
      "description" => "A comprehensive example demonstrating JSON Schema Editor features",
      "type" => "object",
      "properties" => %{
        "userInfo" => %{
          "title" => "User Information",
          "type" => "object",
          "properties" => %{
            "username" => %{
              "type" => "string",
              "title" => "Username",
              "minLength" => 3,
              "maxLength" => 20,
              "pattern" => "^[a-zA-Z0-9_]+$",
              "description" => "Must be 3-20 characters, alphanumeric with underscores"
            },
            "email" => %{
              "type" => "string",
              "title" => "Email Address",
              "format" => "email",
              "description" => "Valid email format"
            },
            "age" => %{
              "type" => "integer",
              "title" => "Age",
              "minimum" => 18,
              "maximum" => 120,
              "description" => "Must be between 18 and 120"
            },
            "birthDate" => %{
              "type" => "string",
              "title" => "Birth Date",
              "format" => "date",
              "description" => "Date of birth in YYYY-MM-DD format"
            }
          },
          "required" => ["username", "email"]
        },
        "contact" => %{
          "title" => "Contact Information",
          "type" => "object",
          "properties" => %{
            "phone" => %{
              "type" => "string",
              "title" => "Phone Number",
              "pattern" => "^\\+?[0-9\\s-]{10,15}$",
              "description" => "International phone number format"
            },
            "address" => %{
              "type" => "object",
              "title" => "Address",
              "properties" => %{
                "street" => %{"type" => "string", "title" => "Street"},
                "city" => %{"type" => "string", "title" => "City"},
                "zipCode" => %{
                  "type" => "string",
                  "title" => "ZIP Code",
                  "pattern" => "^[0-9]{5}(-[0-9]{4})?$",
                  "description" => "US ZIP code format"
                }
              },
              "required" => ["street", "city"]
            }
          }
        },
        "preferences" => %{
          "title" => "User Preferences",
          "type" => "object",
          "properties" => %{
            "theme" => %{
              "type" => "string",
              "title" => "Theme",
              "enum" => ["light", "dark", "system"],
              "default" => "light",
              "description" => "Choose from predefined themes"
            },
            "notifications" => %{
              "type" => "boolean",
              "title" => "Enable Notifications",
              "description" => "Receive email notifications"
            },
            "language" => %{
              "type" => "string",
              "title" => "Language",
              "enum" => ["en", "es", "fr", "de", "ja"],
              "description" => "Preferred language"
            }
          }
        },
        "socialMedia" => %{
          "title" => "Social Media Links",
          "type" => "object",
          "properties" => %{
            "twitter" => %{
              "type" => "string",
              "title" => "Twitter Handle",
              "format" => "uri",
              "pattern" => "^https://twitter\\.com/[a-zA-Z0-9_]{1,15}$"
            },
            "github" => %{
              "type" => "string",
              "title" => "GitHub Profile",
              "format" => "uri",
              "pattern" => "^https://github\\.com/[a-zA-Z0-9-]+$"
            }
          },
          "additionalProperties" => false
        },
        "tags" => %{
          "type" => "array",
          "title" => "Tags",
          "items" => %{
            "type" => "string",
            "minLength" => 2,
            "maxLength" => 15
          },
          "minItems" => 1,
          "maxItems" => 10,
          "uniqueItems" => true,
          "description" => "List of tags (1-10 unique items)"
        },
        "scores" => %{
          "type" => "array",
          "title" => "Test Scores",
          "items" => %{
            "type" => "number",
            "minimum" => 0,
            "maximum" => 100,
            "multipleOf" => 0.5
          },
          "description" => "Test scores between 0-100 in 0.5 increments"
        },
        "metadata" => %{
          "title" => "Metadata",
          "type" => "object",
          "properties" => %{
            "createdAt" => %{
              "type" => "string",
              "title" => "Creation Date",
              "format" => "date-time",
              "description" => "ISO 8601 datetime format"
            },
            "updatedAt" => %{
              "type" => "string",
              "title" => "Last Update",
              "format" => "date-time"
            }
          }
        },
        "accountType" => %{
          "title" => "Account Type",
          "description" => "User account type",
          "type" => "string",
          "enum" => ["free", "premium", "enterprise"]
        },
        "systemInfo" => %{
          "title" => "System Information",
          "type" => "object",
          "properties" => %{
            "apiVersion" => %{
              "title" => "API Version",
              "type" => "string",
              "const" => "1.0",
              "description" => "Fixed API version"
            },
            "termsAccepted" => %{
              "title" => "Terms Accepted",
              "type" => "boolean",
              "const" => true,
              "description" => "Must be true"
            }
          }
        }
      },
      "required" => ["userInfo", "contact"]
    }

    css_path = Path.expand("../assets/css/json_schema_editor.css", __DIR__)
    css_content = File.read!(css_path)

    {:ok, assign(socket, my_schema: schema, css: css_content)}
  end

  def render(assigns) do
    ~H"""
    <style>
      body {
        margin: 0;
      }
    </style>
    <style>
      <%= @css %>
    </style>
    <script>
      window.addEventListener("click", e => {
        const btn = e.target.closest(".jse-btn-copy");
        if (btn) {
          const content = btn.getAttribute("data-content");
          if (content) {
            navigator.clipboard.writeText(content).then(() => {
              btn.classList.add("jse-copied");
              const span = btn.querySelector("span");
              if (span) {
                const oldText = span.innerText;
                span.innerText = "Copied!";
                setTimeout(() => {
                  btn.classList.remove("jse-copied");
                  span.innerText = oldText;
                }, 2000);
              }
            });
          }
        }
      });
    </script>
    <.live_component
      module={JSONSchemaEditor}
      id="editor"
      schema={@my_schema}
      on_save={fn updated_json -> send(self(), {:schema_updated, updated_json}) end}
    />
    """
  end

  def handle_info({:schema_updated, schema}, socket) do
    {:noreply, assign(socket, my_schema: schema)}
  end
end

PhoenixPlayground.start(live: Demo, port: 4040)
