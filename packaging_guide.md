# **Architectural Patterns and Best Practices for Distributing Reusable Phoenix LiveView Components**

## **Executive Summary**

The distribution of reusable user interface (UI) components within the Elixir and Phoenix ecosystem represents a sophisticated intersection of backend functional logic and frontend asset management. Unlike JavaScript-centric ecosystems where a single package manager (NPM) often handles both logic and presentation, the Phoenix LiveView landscape requires library authors to navigate the bifurcation between Hex (for Elixir code) and the asset pipeline (typically esbuild and Tailwind CSS). This report provides an exhaustive, expert-level analysis of the methodologies for packaging, releasing, and maintaining reusable Phoenix LiveView components, with a specific focus on implementing scoped CSS architectures using prefixing strategies (e.g., xyz-...).  
The analysis draws upon a comprehensive review of the current ecosystem, including the paradigm shifts introduced by Phoenix 1.7, the emergence of Tailwind CSS v4, and the diverse distribution models employed by leading libraries such as phoenix\_live\_dashboard, petal\_components, and surface\_ui. We explore the "Asset Gap"—the challenge of shipping static assets alongside compiled BEAM code—and propose robust architectural solutions ranging from source-code scanning to compile-time attribute injection. The report concludes with a definitive implementation roadmap for creating a fully encapsulated, highly compatible component library that respects the distinct boundaries of the Elixir process model and the browser's Document Object Model (DOM).

## ---

**Part I: The Theoretical Framework of Component Distribution**

To understand the best practices for releasing LiveView components, one must first deconstruct the architectural constraints and opportunities presented by the underlying platform. The distribution of a Phoenix component is not merely a matter of file organization; it is an exercise in managing the lifecycle of assets across two distinct runtime environments: the Erlang Virtual Machine (BEAM) and the user's web browser.

### **1.1 The Bifurcation of Dependency Management**

In a standard Phoenix application, dependencies are managed by two distinct, often orthogonal, systems. This dual-structure creates what industry experts refer to as the "Asset Gap," a distribution challenge that every library author must solve.  
First, there is **Hex**, the package manager for the Erlang ecosystem.1 Hex is exceptionally proficient at resolving version constraints for Elixir source code, managing transitive dependencies, and delivering compiled BEAM byte code. When a developer adds {:my\_component, "\~\> 1.0"} to their mix.exs, Hex ensures that the Elixir modules are available at compile time and runtime. It handles the server-side logic of a LiveView—the mount/3, handle\_event/3, and render/1 callbacks—seamlessly.2  
Second, there is the **Asset Pipeline**, historically handled by tools like Brunch or Webpack, and more recently by lightweight wrappers around binary executables like esbuild and tailwind.3 These tools are responsible for processing JavaScript, CSS, images, and fonts. Crucially, Hex does not natively manage these assets in a way that automatically injects them into the host application's build process. When a Hex package is installed, its assets/ directory is downloaded to the deps/ folder, but the host application's esbuild or tailwind process does not automatically know that these files exist or that they should be included in the final bundle.4  
This bifurcation means that a library author cannot simply ship a CSS file in the package and expect it to work. Explicit mechanisms must be engineered to "bridge the gap" between the deps/ directory (where the library lives) and the priv/static/ directory (where the host app serves assets).5

### **1.2 The Evolution of Component Architectures**

The approach to solving this distribution problem has evolved through several distinct phases, each offering lessons for modern package design.  
Phase 1: The "Priv/Static" Era (The Dashboard Model)  
Early Phoenix libraries, and notably the phoenix\_live\_dashboard, solved this by bypassing the build pipeline entirely. In this model, the library author pre-compiles their assets into the priv/static directory of the library itself. The library then provides a Plug.Static configuration that serves these files directly from the library's path.7 This offers high isolation but low customization, making it suitable for admin tools but less ideal for UI kits that need to blend into the user's application.  
Phase 2: The "Vendor" Era (The JavaScript Model)  
As the need for JavaScript interoperability grew, particularly for libraries wrapping complex DOM interactions (like maps or rich text editors), the pattern shifted toward "vendoring." Developers were instructed to manually copy JavaScript files from deps/my\_lib/assets into their own assets/vendor directory.3 While this works, it creates a maintenance burden, as updates to the library require the user to re-copy files, breaking the seamless update promise of semantic versioning.  
Phase 3: The "Source Scan" Era (The Tailwind Model)  
The current state-of-the-art, popularized by the widespread adoption of Tailwind CSS in Phoenix 1.7+, relies on the "Source Scan" model. Here, the library ships uncompiled source code (HEEx templates and CSS), and the host application is configured to "scan" the library's source files during its own build process. This allows for "Tree Shaking"—the removal of unused styles—and ensures that the library's components inherit the host application's design tokens (colors, fonts, spacing).9 This model is the primary focus for general-purpose UI components.

### **1.3 The Scope of the Challenge: CSS Encapsulation**

The user's specific requirement for a scoped prefix like xyz-... points to the fundamental challenge of **CSS Encapsulation**. In a global CSS environment, style leakage is the primary adversary. If a library defines a generic class like .card or .btn, it creates an immediate conflict with the host application's styles or other installed libraries. This phenomenon, known as "Specificity Wars," results in broken layouts and frustrated developers.11  
While modern web standards offer the Shadow DOM as a mechanism for perfect isolation 13, its heavy boundary makes it difficult to share global themes (like a "Dark Mode" class on the \<body\>) or allow the user to easily override styles. Therefore, the Phoenix ecosystem favors "Soft Encapsulation" via naming conventions (BEM-like prefixing) or compile-time attribute injection (Surface-style scoping).14 A reusable package must strictly adhere to one of these strategies to ensure it plays nicely within the multi-tenant environment of a web page.

## ---

**Part II: Architectural Patterns for Release**

Based on the synthesis of the research materials, there are three viable architectural patterns for releasing a LiveView component package. The choice of pattern dictates the file structure, the installation instructions, and the level of customization available to the user.

### **2.1 Pattern A: The Source Integration Model (Recommended for UI Kits)**

This model is currently the industry standard for UI libraries such as petal\_components, flowbite\_phoenix, and phoenix\_ui.10 It is characterized by deep integration into the host application's build pipeline.  
**Architecture:**

* **Elixir Code:** Standard Phoenix.Component modules defined in lib/.  
* **CSS:** Source CSS files (often utilizing @layer directives) located in assets/css/.  
* **Integration:** The user configures their tailwind.config.js (or app.css in Tailwind 4\) to "watch" or "import" the library's files directly from the deps/ directory.

**Advantages:**

* **Performance:** Utilizing the host's Just-In-Time (JIT) compiler means only the CSS actually used in the application is generated. There is no bloat from unused components.  
* **Theming:** The components automatically access the host's theme configuration (e.g., specific shades of blue or font families defined in the user's config).  
* **DX:** It feels "native" to the Phoenix 1.7+ workflow.

**Disadvantages:**

* **Dependency:** It assumes the host application uses a compatible build tool (e.g., Tailwind). If the user is writing vanilla CSS, this model requires extra setup steps.17

### **2.2 Pattern B: The Standalone Asset Model (Recommended for Admin Tools)**

This model, exemplified by phoenix\_live\_dashboard 7, prioritizes isolation over integration. It is ideal for tools that must function reliably regardless of the host application's styling choices (e.g., a debugger overlay or an error reporter).  
**Architecture:**

* **Pre-compilation:** The library author compiles their SCSS/JS into static files (e.g., app.css, app.js) and places them in priv/static/.  
* **Serving:** The library provides a custom Plug that serves these assets from a dedicated route (e.g., /dashboard/assets/app.css).  
* **Isolation:** The CSS typically uses aggressive namespacing or reset techniques to ensure the host's styles do not bleed into the component.

**Advantages:**

* **Reliability:** It works "out of the box" with zero build configuration from the user.  
* **Isolation:** Changes to the host's CSS framework (e.g., switching from Tailwind to Bootstrap) do not break the library's UI.

**Disadvantages:**

* **Performance:** It requires additional HTTP requests to load the separate asset files.  
* **Theming:** It is difficult for the user to customize the look and feel without overriding CSS with \!important.12

### **2.3 Pattern C: The Installer / Copy-Paste Model**

Emerging from the React ecosystem's shadcn/ui trend and adopted by SaladUI 18, this model rejects the concept of a runtime dependency for UI components.  
**Architecture:**

* **Generator:** The library is essentially a Mix task (e.g., mix xyz.install).  
* **Execution:** When run, the task physically copies the .ex component files and .css files into the user's source tree (lib/my\_app\_web/components/).  
* **Ownership:** Once copied, the code belongs to the user. They can modify, delete, or rename it at will.

**Advantages:**

* **Ultimate Flexibility:** The user has total control over the code.  
* **Zero Runtime Dependency:** No risk of the library updating and breaking the UI.

**Disadvantages:**

* **Drift:** It is difficult to push updates or bug fixes to users once they have modified the code.  
* **Bloat:** The user's codebase grows significantly.

## ---

**Part III: The Mechanics of Scoping and Prefixing**

The core requirement of the user's request is to scope the CSS using a prefix like xyz-.... This section provides a deep technical analysis of how to implement this efficiently, avoiding the pitfalls of specificity wars and maintainability issues.

### **3.1 The BEM Methodology in a Utility Context**

The xyz-... prefix strategy is a direct application of the **Block Element Modifier (BEM)** methodology. In the context of a library distributed via the Source Integration Model, this serves two purposes:

1. **Namespace Protection:** It prevents the class xyz-card from conflicting with a user's .card.  
2. **API Surface Definition:** It clearly signals to the developer which classes are part of the library's public API and which are internal implementation details.

Best Practice Implementation:  
A hybrid approach is recommended. Use the xyz- prefix for the identity of the component and for complex custom CSS, but use standard utility classes (from Tailwind) for structural layout where possible. This keeps the custom CSS file small and readable.

Elixir

\# lib/xyz/components/card.ex  
defmodule Xyz.Components.Card do  
  use Phoenix.Component

  def card(assigns) do  
    \~H"""  
    \<div class="xyz-card flex flex-col overflow-hidden rounded-lg shadow-lg"\>  
      \<div class="xyz-card\_\_header px-4 py-2 border-b"\>  
        {@title}  
      \</div\>  
      \<div class="xyz-card\_\_body p-4"\>  
        {@inner\_block}  
      \</div\>  
    \</div\>  
    """  
  end  
end

In this example, xyz-card identifies the component and applies library-specific styling (perhaps a specific background color logic), while flex flex-col handles the layout using the host's utilities.

### **3.2 Specificity Wars and the @layer Directive**

One of the most significant risks in distributing CSS is **Specificity**. If a library ships a CSS file with the rule:

CSS

.xyz-card { background-color: white; }

And the user tries to override it in their HTML:

HTML

\<.card class="bg-gray-100" /\>

If the library's CSS is loaded *after* the Tailwind utilities, or if the selector has equal specificity, the override might fail, leading to frustration. Users often resort to \!important, which creates a maintenance nightmare.12  
The Solution: @layer  
Tailwind and modern CSS support the @layer directive. By defining the library's scoped styles within the components layer, we explicitly tell the browser (and the build tool) that these styles should have lower precedence than utility classes, regardless of their loading order.10  
**assets/css/xyz.css:**

CSS

@layer components {  
 .xyz-card {  
    background-color: var(--xyz-card-bg, \#ffffff);  
    /\* other base styles \*/  
  }  
}

This architectural decision ensures that if a user applies a utility class like bg-gray-100 (which resides in the utilities layer), it will *always* win over the component's base style, ensuring the component is customizable.

### **3.3 CSS Variables for Soft Encapsulation**

While the class prefix xyz- provides namespace isolation, it creates a rigid barrier to theming. To allow users to customize the component without writing overrides, the library should expose **CSS Custom Properties (Variables)** as its styling API.  
Instead of hardcoding colors, the scoped class should reference a variable:

CSS

.xyz-button {  
  background-color: var(--xyz-primary-color, \#3b82f6);  
  color: var(--xyz-text-on-primary, \#ffffff);  
}

This allows the user to define a global theme in their app.css:

CSS

:root {  
  \--xyz-primary-color: \#ef4444; /\* Rebrand the library to red \*/  
}

This pattern blends the safety of scoped classes with the flexibility of global theming.20

### **3.4 Compile-Time Attribute Scoping (The Surface Approach)**

For authors seeking the rigorous isolation of the Shadow DOM without the runtime overhead, **Compile-Time Attribute Injection** is an advanced alternative. This is the strategy employed by surface\_ui.14  
**Mechanism:**

1. **Colocation:** Styles are defined in a file side-by-side with the component (e.g., card.css).  
2. **Compilation:** A custom Mix compiler reads the CSS, generates a unique hash (e.g., s-9651d1c), and rewrites the CSS selectors from .card to .card\[s-9651d1c\].  
3. **Injection:** The component macro automatically injects the attribute s-9651d1c into the HTML root element during compilation.

Comparison:  
While this offers superior encapsulation, implementing a custom compiler is a significant engineering undertaking. For a standard LiveView package, the Manual Prefix (xyz-) strategy is preferred due to its simplicity and compatibility with standard tooling. It relies on convention rather than complex metaprogramming.14

## ---

**Part IV: Implementation Guide \- Building the xyz Package**

This section provides a definitive, step-by-step roadmap for implementing a reusable component package using the **Source Integration Model**. This model offers the best balance of DX, performance, and flexibility.

### **Step 1: Package Structure and Configuration**

Create a new Mix project. The structure must be carefully organized to expose assets.  
xyz\_components/  
├── assets/  
│ ├── css/  
│ │ └── xyz.css \# The core scoped CSS file  
│ ├── js/  
│ │ └── xyz.js \# Entry point for Hooks  
│ └── package.json \# Definition for large dependencies (optional)  
├── lib/  
│ └── xyz\_components/  
│ ├── button.ex  
│ ├── card.ex  
│ └── hooks.ex \# Helper for hook names  
├── mix.exs  
└── README.md  
Configuring mix.exs:  
The package function is the gatekeeper. You must include the assets directory in the files list. If you miss this, the Hex package will not contain your CSS source files, breaking the integration for users.1

Elixir

defp package do  
 ,  
    links: %{"GitHub" \=\> "https://github.com/your/repo"}  
  \]  
end

### **Step 2: Defining the Scoped CSS**

Create assets/css/xyz.css. Use the @layer directive to prevent specificity issues. Use the xyz- prefix for all classes.

CSS

/\* assets/css/xyz.css \*/  
@layer components {  
  /\* Component: Card \*/  
 .xyz-card {  
    /\* Base structural styles that utilities can't handle easily \*/  
    display: block;  
    border-radius: var(--xyz-radius, 0.5rem);  
    border: 1px solid var(--xyz-border, \#e5e7eb);  
    background-color: var(--xyz-card-bg, \#ffffff);  
  }

  /\* Component: Button \*/  
 .xyz-btn {  
    display: inline-flex;  
    align-items: center;  
    padding: 0.5rem 1rem;  
    font-weight: 600;  
    transition: all 0.2s;  
  }  
    
  /\* Modifier: Primary Variant \*/  
 .xyz-btn--primary {  
    background-color: var(--xyz-primary, \#3b82f6);  
    color: white;  
  }  
    
 .xyz-btn--primary:hover {  
    background-color: var(--xyz-primary-dark, \#2563eb);  
  }  
}

### **Step 3: Authoring the Components**

Write your function components in lib/xyz\_components/button.ex. Use Phoenix.Component and the \~H sigil.  
Crucial Detail \- The attr Macro:  
Use the attr macro to define the interface. Importantly, support a class attribute and a global rest attribute to allow users to merge their own classes with your scoped classes.11

Elixir

defmodule XyzComponents.Button do  
  use Phoenix.Component

  attr :variant, :atom, default: :primary, values: \[:primary, :secondary, :outline\]  
  attr :class, :string, default: nil  
  attr :rest, :global \# Allows user to pass phx-click, disabled, etc.  
  slot :inner\_block, required: true

  def button(assigns) do  
    \~H"""  
    \<button  
      class={}  
      {@rest}  
    \>  
      {@inner\_block}  
    \</button\>  
    """  
  end  
end

**Insight:** By placing @class last in the list, and relying on the @layer definition in CSS, user-supplied utilities will correctly override the library defaults if necessary.

### **Step 4: Documentation and User Integration**

This is where many libraries fail. Since the assets are not auto-injected, you must write impeccable documentation instructing the user how to wire up the library.  
**Documentation Draft:**  
**Installation Guide**

1. Add {:xyz\_components, "\~\> 0.1.0"} to your mix.exs.  
2. **Tailwind Configuration:**  
   * **For Tailwind v4:** Open assets/css/app.css and add the @source and @import directives:  
     CSS  
     @import "tailwindcss";

     /\* 1\. Scan the library for class usage \*/  
     @source "../../deps/xyz\_components/\*\*/\*.\*ex";

     /\* 2\. Import the scoped styles \*/  
     @import "../../deps/xyz\_components/assets/css/xyz.css";

   * **For Tailwind v3:** Open assets/tailwind.config.js and add to the content array:  
     JavaScript  
     content: \[  
       "./js/\*\*/\*.js",  
       "../lib/\*\_web/\*\*/\*.\*ex",  
       "../deps/xyz\_components/\*\*/\*.\*ex" // \<-- Add this  
     \],

     Then import the CSS in assets/css/app.css:  
     CSS  
     @import "../../deps/xyz\_components/assets/css/xyz.css";

This documentation leverages the new **Tailwind v4 @source directive**, which is a massive improvement for library authors. It allows the CSS file itself to declare where its content comes from, centralizing configuration.9

## ---

**Part V: Handling JavaScript Hooks and Dependencies**

Complex components often need JavaScript. The "Vendor Import" pattern is the most robust way to handle this without polluting the global namespace.

### **5.1 The Hook Bundle Strategy**

Hex packages cannot rely on npm install being run in the deps directory. Therefore, you should bundle your hooks into a single file or a set of ES modules.  
**Library File (assets/js/xyz.js):**

JavaScript

// A simple hook without external dependencies  
export const XyzTooltip \= {  
  mounted() {  
    this.el.addEventListener("mouseenter", e \=\> {  
      // Logic to show tooltip  
      this.pushEvent("show\_tooltip", {})  
    })  
  }  
}

// A hook wrapping an external library (bundled)  
import Flatpickr from "flatpickr"; // You must bundle this into the file\!

export const XyzDatePicker \= {  
  mounted() {  
    this.fp \= Flatpickr(this.el, {  
      dateFormat: "Y-m-d"  
    });  
  }  
}

Bundling:  
If you use external libraries like flatpickr, you must use a build tool (like esbuild or rollup) inside your library's development process to bundle flatpickr into assets/js/xyz.js before publishing to Hex. Do not ask the user to npm install flatpickr unless it is a massive library (like Mapbox) where version conflicts are a major concern.3

### **5.2 User Integration for Hooks**

Instruct the user to import the hooks in their app.js.

JavaScript

// assets/js/app.js  
import { XyzTooltip, XyzDatePicker } from "../../deps/xyz\_components/assets/js/xyz"

let liveSocket \= new LiveSocket("/live", Socket, {  
  hooks: { XyzTooltip, XyzDatePicker,... }  
})

This ensures that the user's build pipeline processes the hooks, applying minification and polyfills as configured for their specific project.

## ---

**Part VI: Advanced Topics and Ecosystem Analysis**

### **6.1 Testing Reusable Components**

Testing a packaged component requires verifying that it renders the expected HTML and attributes. The Phoenix.ComponentTest module is essential here.

Elixir

defmodule XyzComponents.ButtonTest do  
  use ExUnit.Case  
  import Phoenix.Component  
  import Phoenix.LiveViewTest  
  import XyzComponents.Button

  test "renders button with scoped class" do  
    assigns \= %{}  
    html \= rendered\_to\_string(\~H"""  
    \<.button variant={:primary}\>Click me\</.button\>  
    """)

    assert html \=\~ "xyz-btn"  
    assert html \=\~ "xyz-btn--primary"  
    assert html \=\~ "Click me"  
  end  
end

For testing LiveComponents that involve state and hooks, you must use live\_isolated from Phoenix.LiveViewTest to spin up a lightweight LiveView process during the test.24

### **6.2 The "Installer" Pattern: A Growing Trend**

While this report focuses on the package dependency model, it is worth noting the rise of the **Installer Pattern**. Libraries like SaladUI provide a mix task (mix salad.install) that copies files.  
**Comparison:**

* **Package Model:** Best for strict versioning, ease of use (add to mix.exs), and complex logic that shouldn't be touched (e.g., a rich text editor implementation).  
* **Installer Model:** Best for purely visual components where the user is expected to customize the HTML/Tailwind classes heavily (e.g., a generic card or badge).18

If your xyz library is primarily visual and you expect users to want to change the HTML structure, consider offering a mix xyz.install task *in addition* to the package.

### **6.3 Future Proofing: Tailwind 4 and Beyond**

The shift to Tailwind 4 is significant for library authors. The legacy tailwind.config.js is being deprecated in favor of CSS-native configuration.

* **Impact:** Library authors should prioritize documentation that uses the @source directive.9  
* **Strategy:** Provide a migration guide in your README for users upgrading from Tailwind 3 to 4, explaining how to move the config from tailwind.config.js to app.css.

## ---

**Part VII: Ecosystem Survey and Case Studies**

A comparative analysis of existing libraries validates these architectural choices.

### **Table 1: Comparative Analysis of Asset Distribution Models**

| Library | Distribution Model | CSS Scoping | User Setup Difficulty | Analysis |
| :---- | :---- | :---- | :---- | :---- |
| **Phoenix LiveDashboard** 7 | **Priv/Static** (Standalone) | Strict Prefixing | Low (Plug only) | Best for admin tools. Totally isolated. Hard to theme. |
| **Petal Components** 10 | **Source Integration** | Tailwind Utilities \+ Prefix | Medium (Config edit) | Best for UI kits. High customization. Small bundle. |
| **Flowbite Phoenix** 16 | **Source Integration** \+ Peer Dep | Tailwind \+ NPM | High (Config \+ NPM install) | Powerful, but requires user to manage JS dependencies. |
| **SaladUI** 18 | **Installer** (Copy-Paste) | None (User owns code) | Low (Mix task) | Maximum flexibility. No update path. |
| **Surface UI** 14 | **Compiler Injection** | Attribute Hashing | High (Custom Compiler) | Best encapsulation (Shadow DOM-like). High complexity. |

This table underscores that for a general-purpose, reusable component library, the **Source Integration** model (Petal) strikes the best balance. It avoids the complexity of Surface's compiler while offering better integration than the Dashboard's isolated approach.

## ---

**Conclusion**

Releasing a reusable Phoenix LiveView component package is a deliberate exercise in architectural decision-making. The "Asset Gap" between Elixir and the browser requires explicit bridging strategies.  
To satisfy the requirement of releasing a package with scoped xyz-... CSS:

1. **Adopt the Source Integration Model:** Distribute source files (HEEx and CSS) and leverage the host's build pipeline.  
2. **Implement Hybrid Scoping:** Use the xyz- prefix for component identity and specific custom styles, but leverage standard Tailwind utilities for layout.  
3. **Utilize @layer:** Protect your styles from specificity wars by placing them in the components layer.  
4. **Expose CSS Variables:** Enable theming via custom properties rather than forcing users to write override selectors.  
5. **Vendor Hooks:** Bundle standard JS hooks and export them via an ES module, instructing users to import them in app.js.

By adhering to these patterns, you align your library with the modern Phoenix 1.7+ ecosystem, ensuring it is performant, maintainable, and a joy for other developers to use.

#### **Works cited**

1. Hex, accessed January 14, 2026, [https://hex.pm/](https://hex.pm/)  
2. Phoenix LiveView Tutorial: Build a Live Chat App from Scratch | Curiosum, accessed January 14, 2026, [https://www.curiosum.com/blog/phoenix-live-view-tutorial](https://www.curiosum.com/blog/phoenix-live-view-tutorial)  
3. Asset Management — Phoenix v1.8.3 \- Hexdocs, accessed January 14, 2026, [https://hexdocs.pm/phoenix/asset\_management.html](https://hexdocs.pm/phoenix/asset_management.html)  
4. Interaction of Tailwind and esbuild confusing in a new project created with phx.new · Issue \#5912 · phoenixframework/phoenix \- GitHub, accessed January 14, 2026, [https://github.com/phoenixframework/phoenix/issues/5912](https://github.com/phoenixframework/phoenix/issues/5912)  
5. Directory structure — Phoenix v1.8.3 \- Hexdocs, accessed January 14, 2026, [https://hexdocs.pm/phoenix/directory\_structure.html](https://hexdocs.pm/phoenix/directory_structure.html)  
6. Is it possible to include resource files when packaging my project using Mix/escript?, accessed January 14, 2026, [https://elixirforum.com/t/is-it-possible-to-include-resource-files-when-packaging-my-project-using-mix-escript/730](https://elixirforum.com/t/is-it-possible-to-include-resource-files-when-packaging-my-project-using-mix-escript/730)  
7. phoenix\_live\_dashboard \- Hex.pm, accessed January 14, 2026, [https://hex.pm/packages/phoenix\_live\_dashboard](https://hex.pm/packages/phoenix_live_dashboard)  
8. phoenixframework/phoenix\_live\_dashboard: Realtime dashboard with metrics, request logging, plus storage, OS and VM insights \- GitHub, accessed January 14, 2026, [https://github.com/phoenixframework/phoenix\_live\_dashboard](https://github.com/phoenixframework/phoenix_live_dashboard)  
9. Components \- Petal Framework, accessed January 14, 2026, [https://petal.build/components](https://petal.build/components)  
10. README — petal\_components v3.0.1 \- Hexdocs, accessed January 14, 2026, [https://hexdocs.pm/petal\_components/readme.html](https://hexdocs.pm/petal_components/readme.html)  
11. Custom styling with LiveView function component attributes · The Phoenix Files \- Fly.io, accessed January 14, 2026, [https://fly.io/phoenix-files/customizable-classes-lv-component/](https://fly.io/phoenix-files/customizable-classes-lv-component/)  
12. Styling Static and dynamic textareas in phoenix liveview \- Stack Overflow, accessed January 14, 2026, [https://stackoverflow.com/questions/79029152/styling-static-and-dynamic-textareas-in-phoenix-liveview](https://stackoverflow.com/questions/79029152/styling-static-and-dynamic-textareas-in-phoenix-liveview)  
13. CSS scoping \- MDN Web Docs, accessed January 14, 2026, [https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Scoping](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Scoping)  
14. Scoped CSS styles \- Surface UI, accessed January 14, 2026, [https://surface-ui.org/scoped\_css](https://surface-ui.org/scoped_css)  
15. Phoenix UI v0.1.9 \- Hexdocs, accessed January 14, 2026, [https://hexdocs.pm/phoenix\_ui/readme.html](https://hexdocs.pm/phoenix_ui/readme.html)  
16. FlowbitePhoenix v0.1.2 \- Hexdocs, accessed January 14, 2026, [https://hexdocs.pm/flowbite\_phoenix/](https://hexdocs.pm/flowbite_phoenix/)  
17. Where should the CSS reside in a Phoenix Liveview app with \--no-tailwind? \- Elixir Forum, accessed January 14, 2026, [https://elixirforum.com/t/where-should-the-css-reside-in-a-phoenix-liveview-app-with-no-tailwind/57256](https://elixirforum.com/t/where-should-the-css-reside-in-a-phoenix-liveview-app-with-no-tailwind/57256)  
18. bluzky/salad\_ui: Phoenix Liveview component library ... \- GitHub, accessed January 14, 2026, [https://github.com/bluzky/salad\_ui](https://github.com/bluzky/salad_ui)  
19. Using Tailwind CSS in Phoenix 1.7 \- The Pragmatic Studio, accessed January 14, 2026, [https://pragmaticstudio.com/tutorials/using-tailwind-css-in-phoenix](https://pragmaticstudio.com/tutorials/using-tailwind-css-in-phoenix)  
20. backpex/AGENTS.md at develop \- GitHub, accessed January 14, 2026, [https://github.com/naymspace/backpex/blob/develop/AGENTS.md](https://github.com/naymspace/backpex/blob/develop/AGENTS.md)  
21. Library Usage Guide — ElixirDashboard v0.2.0 \- Hexdocs, accessed January 14, 2026, [https://hexdocs.pm/elixir\_dashboard/library\_usage.html](https://hexdocs.pm/elixir_dashboard/library_usage.html)  
22. Phoenix.Component — Phoenix LiveView v1.1.19 \- Hexdocs, accessed January 14, 2026, [https://hexdocs.pm/phoenix\_live\_view/Phoenix.Component.html](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)  
23. Tailwind CSS Phoenix (Elixir) \- Flowbite, accessed January 14, 2026, [https://flowbite.com/docs/getting-started/phoenix/](https://flowbite.com/docs/getting-started/phoenix/)  
24. Building Scalable UI Systems in Phoenix LiveView with Reusable HEEx Components, accessed January 14, 2026, [https://dev.to/hexshift/building-scalable-ui-systems-in-phoenix-liveview-with-reusable-heex-components-1m3j](https://dev.to/hexshift/building-scalable-ui-systems-in-phoenix-liveview-with-reusable-heex-components-1m3j)  
25. petal\_cli/README.md at main \- GitHub, accessed January 14, 2026, [https://github.com/trance128/petal\_cli/blob/main/README.md](https://github.com/trance128/petal_cli/blob/main/README.md)