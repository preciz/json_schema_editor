export const JSONSchemaEditorClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const content = this.el.getAttribute("data-content");
      if (content) {
        navigator.clipboard.writeText(content).then(() => {
          this.el.classList.add("jse-copied");
          const span = this.el.querySelector("span");
          if (span) {
            const oldText = span.innerText;
            span.innerText = "Copied!";
            setTimeout(() => {
              this.el.classList.remove("jse-copied");
              span.innerText = oldText;
            }, 2000);
          }
        });
      }
    });
  }
};

export const Hooks = {
  JSONSchemaEditorClipboard
};
