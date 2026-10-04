import { Controller } from "@hotwired/stimulus"

// A <select> whose options' values are URLs: choosing one goes there. Replaces legacy's inline
// `onchange="window.location.href = '/leagues/' + value"` on the Leagues page's "Sort By" dropdown.
export default class extends Controller {
  go() {
    const url = this.element.value
    // Turbo.visit keeps this a Turbo Drive navigation (no full page reload); location is the fallback if Turbo
    // somehow isn't there.
    if (window.Turbo) {
      window.Turbo.visit(url)
    } else {
      window.location.assign(url)
    }
  }
}
