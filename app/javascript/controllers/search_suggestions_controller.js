
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  connect() {
    this.timeout = null
    this.abortController = null
    this.isComposing = false
    this.activeIndex = -1
  }

  disconnect() {
    this.cancelRequest()
  }

  compositionStart() {
    this.isComposing = true
    this.cancelRequest()
  }

  compositionEnd() {
    this.isComposing = false
    this.search()
  }

  search() {
    if (this.isComposing) return

    this.cancelRequest()
    this.clearResults()

    const query = this.inputTarget.value.trim()

    if (query.length < 2 || query.length > 100) return

    this.timeout = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 400)
  }

  closeOnEscape(event) {
    if (event.isComposing || this.isComposing) return

    event.preventDefault()
    this.cancelRequest()
    this.clearResults()
  }

  closeOnOutsideClick(event) {
    if (this.element.contains(event.target)) return

    this.cancelRequest()
    this.clearResults()
  }

  handleKeydown(event) {
    if (event.isComposing || this.isComposing) return
    if (this.resultsTarget.hidden) return

    const buttons = this.suggestionButtons()

    if (buttons.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activeIndex = (this.activeIndex + 1) % buttons.length
      this.highlightActiveButton(buttons)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activeIndex =
        (this.activeIndex - 1 + buttons.length) % buttons.length
      this.highlightActiveButton(buttons)
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      buttons[this.activeIndex].click()
    }
  }

  suggestionButtons() {
    return Array.from(
      this.resultsTarget.querySelectorAll(".search-suggestion-item")
    )
  }

  highlightActiveButton(buttons) {
    buttons.forEach((button, index) => {
      button.classList.toggle(
        "search-suggestion-item--active",
        index === this.activeIndex
      )
    })

    buttons[this.activeIndex]?.scrollIntoView({
      block: "nearest"
    })
  }

  async fetchSuggestions(query) {
    const controller = new AbortController()
    this.abortController = controller

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", query)

      const response = await fetch(url, {
        signal: controller.signal,
        headers: { Accept: "application/json" }
      })

      if (!response.ok) throw new Error("検索候補の取得に失敗しました")

      const data = await response.json()

      if (controller.signal.aborted ||
          this.inputTarget.value.trim() !== query ||
          this.isComposing) return

      this.renderSuggestions(data.suggestions || [])
    } catch (error) {
      if (error.name === "AbortError") return

      console.error("検索候補取得エラー:", error)
      this.clearResults()
    }
  }

  renderSuggestions(suggestions) {
    this.clearResults()

    if (suggestions.length === 0) return

    const fragment = document.createDocumentFragment()

    suggestions.forEach((suggestion) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "search-suggestion-item"

      const label = document.createElement("span")
      label.className = "search-suggestion-text"

      const name = document.createElement("strong")
      name.textContent = suggestion.name || ""

      const artist = document.createElement("small")
      artist.textContent = suggestion.artist || ""

      label.append(name, artist)

      if (suggestion.image_url) {
        const image = document.createElement("img")
        image.src = suggestion.image_url
        image.alt = ""
        image.className = "search-suggestion-image"
        button.appendChild(image)
      }

      button.appendChild(label)

      button.addEventListener("click", () => {
        this.inputTarget.value = suggestion.name
        this.cancelRequest()
        this.clearResults()
        this.inputTarget.form.requestSubmit()
      })

      fragment.appendChild(button)
    })

    this.resultsTarget.appendChild(fragment)
    this.resultsTarget.hidden = false
    this.activeIndex = -1
  }

  clearResults() {
    this.resultsTarget.replaceChildren()
    this.resultsTarget.hidden = true
    this.activeIndex = -1
  }

  cancelRequest() {
    clearTimeout(this.timeout)
    this.abortController?.abort()
    this.abortController = null
  }
}
