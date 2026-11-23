import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { savedFields: Object }

  connect() {
    this.submitting = false
  }

  get hasWork() {
    if (this.hasSavedFieldsValue) return this.hasEditedFields

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

  get hasEditedFields() {
    const form = this.element.querySelector(".memory-compose-form")
    if (!form) return false

    const fields = new FormData(form)
    const savedFields = this.savedFieldsValue
    const changedFields = ["title", "body", "spotify_track_id", "spotify_album_id"].some((name) => {
      const saved = savedFields[name].replace(/\r\n?/g, "\n")
      return fields.get(`memory[${name}]`) !== saved
    })
    const tagIds = fields.getAll("memory[tag_ids][]").filter(Boolean).sort()

    return changedFields ||
      Boolean(fields.get("memory[new_tag_name]")) ||
      JSON.stringify(tagIds) !== JSON.stringify(savedFields.tag_ids)
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
