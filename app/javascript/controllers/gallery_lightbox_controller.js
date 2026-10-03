import { Controller } from "@hotwired/stimulus"

// The Screenshots page's lightbox -- a native <dialog> standing in for legacy's Colorbox (jQuery). Esc-to-close
// and the backdrop come free from <dialog>; this swaps the image, keeps the caption and "image X of N" counter
// current, and wraps prev/next around the single flat list of screenshots (Colorbox treated them all as one group
// too). Same shape as storks-now-rails8's controller of the same name, plus the caption/counter and
// click-the-backdrop-to-close that Colorbox had.
export default class extends Controller {
  static targets = ["dialog", "image", "caption", "counter"]
  static values = { images: Array }

  open(event) {
    event.preventDefault()
    this.show(parseInt(event.currentTarget.dataset.index, 10))
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // A click on the ::backdrop is dispatched to the <dialog> element itself (the dialog has no padding, so a click
  // anywhere on its content hits a child instead).
  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  next() {
    this.show(this.currentIndex + 1)
  }

  prev() {
    this.show(this.currentIndex - 1)
  }

  show(index) {
    const count = this.imagesValue.length
    this.currentIndex = ((index % count) + count) % count
    const screenshot = this.imagesValue[this.currentIndex]
    this.imageTarget.src = screenshot.src
    this.imageTarget.alt = screenshot.caption
    this.captionTarget.textContent = screenshot.caption
    this.counterTarget.textContent = `image ${this.currentIndex + 1} of ${count}`
  }
}
