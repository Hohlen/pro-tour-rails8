import { Controller } from "@hotwired/stimulus"

// The Leagues page's "find your league" box: as you type, rows that don't match drop out of the table and the
// header's count becomes "12 of 69 leagues". Each row carries its searchable text (name, id and format, lowercased)
// in data-search; every word typed has to appear in it, in any order, so "tiger memorial" finds "2018 Tiger Woods
// Memorial". The page is complete without this -- it's only a filter over rows the server already rendered.
export default class extends Controller {
  static targets = ["search", "input", "row", "count", "noMatch", "query"]

  connect() {
    // The box is rendered hidden: without JavaScript it would do nothing, so it only appears once this runs.
    this.searchTarget.hidden = false
    // Also re-applies whatever is in the field if the browser restores it (back/forward) or Turbo restores a snapshot.
    this.filter()
  }

  filter() {
    const typed = this.inputTarget.value.trim()
    const words = typed.toLowerCase().split(/\s+/).filter(Boolean)
    const total = this.rowTargets.length

    let shown = 0
    this.rowTargets.forEach((row) => {
      const matches = words.every((word) => row.dataset.search.includes(word))
      row.hidden = !matches
      if (!matches) return

      shown += 1
      // Keep the # column counting 1..n and the zebra striping unbroken across the rows that remain: the table's
      // :nth-child stripes would still count the hidden rows.
      row.firstElementChild.textContent = shown
      row.classList.toggle("lgRowAlt", shown % 2 === 1)
    })

    const noun = total === 1 ? "league" : "leagues"
    this.countTarget.textContent = words.length ? `${shown} of ${total} ${noun}` : `${total} ${noun}`
    this.noMatchTarget.hidden = !(words.length && shown === 0)
    this.queryTarget.textContent = typed
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }
}
