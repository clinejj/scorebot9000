import { Controller } from "@hotwired/stimulus"

// Refreshes the page in place (Turbo morph) every `interval` seconds while
// it's visible. Live pages also get pushed refreshes over Action Cable; this
// is the fallback when the socket isn't connected.
export default class extends Controller {
  static values = { interval: { type: Number, default: 20 } }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  refresh() {
    if (document.visibilityState !== "visible") return
    window.Turbo.visit(window.location.href, { action: "replace" })
  }
}
