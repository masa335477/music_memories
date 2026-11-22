import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.submitting = false
  }

  get hasWork() {
    const title = this.element.querySelector('[name="memory[title]"]')
    const body = this.element.querySelector('[name="memory[body]"]')
    const track = this.element.querySelector('[name="memory[spotify_track_id]"]')
    const album = this.element.querySelector('[name="memory[spotify_album_id]"]')

    return Boolean(
      title?.value.length > 0 ||
      body?.value.length > 0 ||
      track?.value ||
      album?.value
    )
  }

  confirmSubmit(event) {
    if (this.hasWork && !window.confirm(this.message)) {
      event.preventDefault()
      return
    }

    this.submitting = true
  }

  confirmVisit(event) {
    if (this.submitting || !this.hasWork) return

    if (!window.confirm(this.message)) {
      event.preventDefault()
    }
  }

  confirmUnload(event) {
    if (this.submitting || !this.hasWork) return

    event.preventDefault()
    event.returnValue = ""
  }

  get message() {
    return "作業内容が失われる可能性があります。よろしいですか？"
  }
}