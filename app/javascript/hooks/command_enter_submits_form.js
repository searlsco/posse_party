document.addEventListener('keydown', (event) => {
  if (event.key === 'Enter' && event.metaKey) {
    if (!document.activeElement) return
    const closestForm = document.activeElement.closest('form')
    if (closestForm) {
      event.preventDefault()
      closestForm.requestSubmit()
    }
  }
})
