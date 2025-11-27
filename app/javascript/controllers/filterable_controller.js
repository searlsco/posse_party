import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    query: String,
    backendMode: { type: Boolean, default: false }
  }

  static targets = ['filterable', 'flag', 'resetControl', 'queryInput', 'clearButton', 'container']

  connect () {
    this.searchTimeout = null
    this.activeSearchQuery = null
    this.queryCache = new Map() // normalizedQuery -> array of post IDs
    this.postCache = new Map() // postId -> post HTML

    this.updateClearButton()

    if (this.backendModeValue) {
      this.cacheCurrentState()
      this.setupFrameListener()
    }
  }

  disconnect () {
    clearTimeout(this.searchTimeout)
  }

  search (e) {
    const query = e.target.value.trim()

    this.updateClearButton()

    if (this.backendModeValue) {
      this.debounceSearch(e.target.value)
    } else {
      this.queryValue = this.massage(query)
    }
  }

  keydown (e) {
    if (e.key === 'Escape') {
      this.clear(e)
    }
  }

  clear (e) {
    e?.preventDefault()

    this.clearButtonTarget?.classList.add('hidden')

    if (this.backendModeValue) {
      this.performSearch('')
    } else {
      this.queryInputTarget.value = ''
      this.queryValue = ''
    }
  }

  // Backend mode methods

  debounceSearch (rawQuery) {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => this.performSearch(rawQuery), 400)
  }

  performSearch (rawQuery) {
    const normalized = this.normalize(rawQuery)

    if (this.activeSearchQuery === normalized) return

    const cachedPostIds = this.queryCache.get(normalized)
    if (cachedPostIds !== undefined) {
      this.displayCachedPosts(cachedPostIds, normalized)
      this.updateUrl(rawQuery)
      this.syncInput(rawQuery)
      return
    }

    const form = this.queryInputTarget?.closest('form')
    if (!form) return

    if (!normalized) {
      window.location.href = window.location.pathname
      return
    }

    this.activeSearchQuery = normalized

    const originalValue = this.queryInputTarget.value
    this.queryInputTarget.value = normalized
    form.requestSubmit()
    this.queryInputTarget.value = originalValue
  }

  // Frontend mode methods

  queryValueChanged () {
    this.refilter()
    this.updateClearButton()
  }

  flagsChanged () {
    this.refilter()
  }

  clearFilters () {
    if (this.backendModeValue) {
      window.location.href = window.location.pathname
    } else {
      this.queryValue = ''
      this.queryInputTarget.value = ''
      this.flagTargets.forEach(f => { f.checked = true })
      this.updateResetControl()
      this.updateClearButton()
    }
  }

  // Private

  normalize (query) {
    return query.trim().toLowerCase()
  }

  updateClearButton () {
    const hasText = this.queryInputTarget?.value.length > 0
    this.clearButtonTarget?.classList.toggle('hidden', !hasText)
  }

  cacheCurrentState () {
    const frame = document.getElementById('posts-search-frame')
    if (!frame) return

    const query = this.normalize(this.queryInputTarget?.value || '')
    const postElements = frame.querySelectorAll('[data-post-id]')
    const postIds = []

    postElements.forEach(element => {
      const postId = element.dataset.postId
      postIds.push(postId)
      this.postCache.set(postId, element.outerHTML)
    })

    this.queryCache.set(query, postIds)

    // Cache pagination frame if present
    const nextPageFrame = frame.querySelector('turbo-frame[loading="lazy"]')
    if (nextPageFrame) {
      this.queryCache.set(`${query}:hasMore`, true)
      this.queryCache.set(`${query}:nextPageFrame`, nextPageFrame.outerHTML)
    } else {
      this.queryCache.set(`${query}:hasMore`, false)
    }
  }

  displayCachedPosts (postIds, normalizedQuery) {
    const frame = document.getElementById('posts-search-frame')
    if (!frame) return

    if (postIds.length === 0) {
      // For empty results, let the server handle it to get proper empty state
      // This avoids hardcoding HTML in JS
      const form = this.queryInputTarget?.closest('form')
      if (form) {
        this.activeSearchQuery = normalizedQuery
        const originalValue = this.queryInputTarget.value
        this.queryInputTarget.value = normalizedQuery
        form.requestSubmit()
        this.queryInputTarget.value = originalValue
      }
      return
    }

    const postHtmlArray = postIds.map(id => this.postCache.get(id)).filter(Boolean)

    if (postHtmlArray.length === 0) return // Cache miss

    // Get the container element (either explicit target or the frame itself)
    const container = this.hasContainerTarget ? this.containerTarget : frame

    // Update the container with cached posts
    container.innerHTML = postHtmlArray.join('')

    // Add pagination if needed (only if container is the frame itself)
    if (container === frame) {
      const hasMore = this.queryCache.get(`${normalizedQuery}:hasMore`)
      const nextPageHtml = this.queryCache.get(`${normalizedQuery}:nextPageFrame`)

      if (hasMore && nextPageHtml) {
        frame.insertAdjacentHTML('beforeend', nextPageHtml)
      }
    }

    frame.classList.add('opacity-75')
    frame.addEventListener('turbo:frame-load', () => {
      frame.classList.remove('opacity-75')
    }, { once: true })
  }

  updateUrl (rawQuery) {
    const url = new URL(window.location)

    if (this.normalize(rawQuery)) {
      url.searchParams.set('q', rawQuery)
    } else {
      url.searchParams.delete('q')
    }

    window.history.pushState({}, '', url)
  }

  syncInput (value) {
    if (this.queryInputTarget?.value !== value) {
      this.queryInputTarget.value = value
      this.updateClearButton()
    }
  }

  setupFrameListener () {
    const frame = document.getElementById('posts-search-frame')
    frame?.addEventListener('turbo:frame-load', () => {
      setTimeout(() => {
        const submittedQuery = this.activeSearchQuery || ''
        this.activeSearchQuery = null

        this.cacheCurrentState()

        const currentValue = this.queryInputTarget?.value || ''
        const currentNormalized = this.normalize(currentValue)

        if (currentNormalized !== submittedQuery) {
          this.performSearch(currentValue)
        }
      }, 100)
    })
  }

  // Frontend filtering

  refilter () {
    if (!this.backendModeValue) {
      this.filterableTargets.forEach(el => {
        el.classList.toggle('hidden', this.shouldHide(el))
      })
      this.updateResetControl()
    }
  }

  updateResetControl () {
    if (!this.hasResetControlTarget) return

    const hiddenCount = this.filterableTargets.filter(el => el.classList.contains('hidden')).length

    if (hiddenCount >= this.filterableTargets.length) {
      this.resetControlTarget.innerHTML = `
        <span class="font-semibold italic">All ${this.filterableTargets.length} items filtered.</span>
        <a href="#" data-action="click->filterable#clearFilters" class="text-accent">Reset?</a>
      `
    } else if (hiddenCount > 0) {
      this.resetControlTarget.innerHTML = `
        <span class="font-semibold italic">Showing ${this.filterableTargets.length - hiddenCount} of ${this.filterableTargets.length} items.</span>
        <a href="#" data-action="click->filterable#clearFilters" class="text-accent">Reset filters?</a>
      `
    } else {
      this.resetControlTarget.innerHTML = ''
    }
  }

  shouldHide (el) {
    return this.doesntMatchQuery(el) || this.excludedByFlags(el)
  }

  excludedByFlags (el) {
    if (el.dataset.filterableFlags) {
      const enabledFlags = this.flagTargets.filter(f => f.checked).map(f => f.name)
      return el.dataset.filterableFlags.split(',').every(flag => !enabledFlags.includes(flag))
    } else if (this.flagTargets.every(f => f.checked)) {
      return false
    } else {
      return true
    }
  }

  doesntMatchQuery (el) {
    if (!this.queryValue) return

    const queryTokens = this.massage(this.queryValue).split(/\s+/)
    const elementTokens = this.massage(el.dataset.content || el.textContent).split(/\s+/)
    return !queryTokens.every(queryToken => elementTokens.some(elementToken => elementToken.startsWith(queryToken)))
  }

  massage (s) {
    return s.trim().toLowerCase().replace(/[^\w\s]/g, '')
  }
}
