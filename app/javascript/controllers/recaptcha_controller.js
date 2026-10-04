import { Controller } from "@hotwired/stimulus"

// Renders Google's reCAPTCHA "I'm not a robot" widget into its element. Google's own auto-render only runs when its
// script first executes, which with Turbo Drive (no full page load on navigation) would be on whichever page the
// visitor happened to land on first -- not this one. So the widget is rendered explicitly, each time the form
// appears, including after a failed submission re-renders it.
//
// The script is loaded once per page lifetime (the module-level promise) and shared by every connect.
let loading

function loadRecaptcha() {
  if (window.grecaptcha?.render) return Promise.resolve(window.grecaptcha)

  loading ||= new Promise((resolve, reject) => {
    const script = document.createElement("script")
    script.src = "https://www.google.com/recaptcha/api.js?render=explicit"
    script.async = true
    script.defer = true
    script.onload = () => window.grecaptcha.ready(() => resolve(window.grecaptcha))
    script.onerror = () => {
      loading = null // let a later visit try again
      reject(new Error("reCAPTCHA script failed to load"))
    }
    document.head.appendChild(script)
  })
  return loading
}

export default class extends Controller {
  static values = { sitekey: String }

  async connect() {
    try {
      const grecaptcha = await loadRecaptcha()
      // The visitor may have navigated away while the script was loading.
      if (!this.element.isConnected) return
      grecaptcha.render(this.element, { sitekey: this.sitekeyValue })
    } catch (error) {
      // Blocked by an ad blocker, or no connection to Google. Without the widget the form can't be sent, so say so.
      this.element.textContent =
        "The security challenge couldn't be loaded. Please check your connection and reload this page."
      this.element.classList.add("ctRecaptcha-error")
    }
  }
}
