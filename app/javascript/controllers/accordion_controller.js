import { Controller } from "@hotwired/stimulus"

// Drives the FAQs and Legal pages' "Expand All" / "Collapse All" buttons, and keeps each trigger's .collapsed
// class (which the chevron-rotate CSS keys off -- see .faqItem-toggle in faq.css) in sync via Bootstrap's own
// shown.bs.collapse/hidden.bs.collapse events. Same controller as storks-now-rails8's (see there for the long
// story about why syncing from the events beats relying on Bootstrap's own trigger bookkeeping).
//
// Bootstrap is loaded as a plain global script (not an importmap module, see application.html.erb), so its JS
// API is reached via window.bootstrap rather than an import.
export default class extends Controller {
  connect() {
    this.element.addEventListener("shown.bs.collapse", this.syncTrigger)
    this.element.addEventListener("hidden.bs.collapse", this.syncTrigger)
  }

  disconnect() {
    this.element.removeEventListener("shown.bs.collapse", this.syncTrigger)
    this.element.removeEventListener("hidden.bs.collapse", this.syncTrigger)
  }

  syncTrigger = (event) => {
    const trigger = this.element.querySelector(`[data-bs-toggle="collapse"][href="#${event.target.id}"]`)
    if (!trigger) return
    const expanded = event.type === "shown.bs.collapse"
    trigger.classList.toggle("collapsed", !expanded)
    trigger.setAttribute("aria-expanded", String(expanded))
  }

  expandAll() {
    this.panels.forEach((panel) => window.bootstrap.Collapse.getOrCreateInstance(panel, { toggle: false }).show())
  }

  collapseAll() {
    this.panels.forEach((panel) => window.bootstrap.Collapse.getOrCreateInstance(panel, { toggle: false }).hide())
  }

  get panels() {
    return this.element.querySelectorAll(".collapse")
  }
}
