import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "endpointType", "urlFields", "ipFields", "portFields", "smtpFields", "dnsFields"
  ]

  connect() {
    this.showFieldsForType(this.endpointTypeTarget.value)
    this.endpointTypeTarget.addEventListener("change", () => {
      this.showFieldsForType(this.endpointTypeTarget.value)
    })
  }

  showFieldsForType(type) {
    this.hideAllFields()
    switch(type) {
      case "url":
        if (this.hasUrlFieldsTarget) this.urlFieldsTarget.style.display = "block"
        break
      case "ip":
        if (this.hasIpFieldsTarget) this.ipFieldsTarget.style.display = "block"
        break
      case "port":
        if (this.hasIpFieldsTarget) this.ipFieldsTarget.style.display = "block"
        if (this.hasPortFieldsTarget) this.portFieldsTarget.style.display = "block"
        break
      case "ssl":
        if (this.hasUrlFieldsTarget) this.urlFieldsTarget.style.display = "block"
        break
      case "smtp":
        if (this.hasSmtpFieldsTarget) this.smtpFieldsTarget.style.display = "block"
        break
      case "dns":
        if (this.hasDnsFieldsTarget) this.dnsFieldsTarget.style.display = "block"
        break
      case "page_speed":
        if (this.hasUrlFieldsTarget) this.urlFieldsTarget.style.display = "block"
        break
      default:
        if (this.hasUrlFieldsTarget) this.urlFieldsTarget.style.display = "block"
    }
  }

  hideAllFields() {
    if (this.hasUrlFieldsTarget) this.urlFieldsTarget.style.display = "none"
    if (this.hasIpFieldsTarget) this.ipFieldsTarget.style.display = "none"
    if (this.hasPortFieldsTarget) this.portFieldsTarget.style.display = "none"
    if (this.hasSmtpFieldsTarget) this.smtpFieldsTarget.style.display = "none"
    if (this.hasDnsFieldsTarget) this.dnsFieldsTarget.style.display = "none"
  }
} 