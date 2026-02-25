import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar", "monthTitle", "slots", "bookingForm", "startTime", "endTime", "timezoneInput", "timezone"]
  static values = { slug: String, maxFutureDays: Number, duration: Number, linkTimezone: String }

  connect() {
    this.detectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone
    this.selectedTimezone = this.detectedTimezone
    this.today = new Date()
    this.today.setHours(0, 0, 0, 0)
    this.currentMonth = new Date(this.today.getFullYear(), this.today.getMonth(), 1)
    this.selectedDate = null

    this.populateTimezones()
    this.renderCalendar()
  }

  populateTimezones() {
    const select = this.timezoneTarget
    const common = [
      "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles",
      "America/Phoenix", "America/Anchorage", "Pacific/Honolulu",
      "America/Toronto", "America/Vancouver",
      "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Amsterdam",
      "Europe/Rome", "Europe/Madrid", "Europe/Zurich",
      "Asia/Tokyo", "Asia/Shanghai", "Asia/Kolkata", "Asia/Dubai",
      "Asia/Singapore", "Asia/Hong_Kong",
      "Australia/Sydney", "Australia/Melbourne", "Australia/Perth",
      "Pacific/Auckland",
      "Etc/UTC"
    ]

    // Ensure detected timezone is in the list
    const timezones = common.includes(this.detectedTimezone)
      ? common
      : [this.detectedTimezone, ...common]

    select.innerHTML = ""
    timezones.forEach(tz => {
      const option = document.createElement("option")
      option.value = tz
      option.textContent = tz.replace(/_/g, " ")
      if (tz === this.detectedTimezone) option.selected = true
      select.appendChild(option)
    })
  }

  timezoneChanged() {
    this.selectedTimezone = this.timezoneTarget.value
    if (this.selectedDate) {
      this.fetchSlots(this.selectedDate)
    }
  }

  prevMonth() {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() - 1, 1)
    this.renderCalendar()
  }

  nextMonth() {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + 1, 1)
    this.renderCalendar()
  }

  renderCalendar() {
    const year = this.currentMonth.getFullYear()
    const month = this.currentMonth.getMonth()

    const monthNames = ["January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"]
    this.monthTitleTarget.textContent = `${monthNames[month]} ${year}`

    const cal = this.calendarTarget
    cal.innerHTML = ""

    // Day headers (Mon-Sun)
    const dayHeaders = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    dayHeaders.forEach(day => {
      const el = document.createElement("div")
      el.className = "text-xs font-medium text-gray-500 py-2"
      el.textContent = day
      cal.appendChild(el)
    })

    // First day of month (0=Sun, adjust to Mon=0)
    const firstDay = new Date(year, month, 1).getDay()
    const startOffset = (firstDay + 6) % 7

    // Days in month
    const daysInMonth = new Date(year, month + 1, 0).getDate()

    // Max date
    const maxDate = new Date(this.today)
    maxDate.setDate(maxDate.getDate() + this.maxFutureDaysValue)

    // Empty cells before first day
    for (let i = 0; i < startOffset; i++) {
      const el = document.createElement("div")
      cal.appendChild(el)
    }

    // Day cells
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day)
      const el = document.createElement("button")
      el.type = "button"
      el.textContent = day

      const isPast = date < this.today
      const isBeyondMax = date > maxDate
      const isSelected = this.selectedDate && date.toDateString() === this.selectedDate.toDateString()

      if (isPast || isBeyondMax) {
        el.className = "py-2 text-sm text-gray-300 cursor-not-allowed rounded-md"
        el.disabled = true
      } else if (isSelected) {
        el.className = "py-2 text-sm font-semibold text-white bg-indigo-600 rounded-md"
      } else {
        el.className = "py-2 text-sm text-gray-900 hover:bg-indigo-50 rounded-md cursor-pointer"
        el.addEventListener("click", () => this.selectDate(date))
      }

      cal.appendChild(el)
    }
  }

  selectDate(date) {
    this.selectedDate = date
    this.renderCalendar()
    this.fetchSlots(date)
    this.hideBookingForm()
  }

  async fetchSlots(date) {
    const dateStr = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`
    const url = `/book/${this.slugValue}/availability?date=${dateStr}&timezone=${encodeURIComponent(this.selectedTimezone)}`

    this.slotsTarget.innerHTML = '<p class="text-sm text-gray-500">Loading...</p>'

    try {
      const response = await fetch(url)
      if (!response.ok) throw new Error("Failed to load")

      const data = await response.json()
      this.renderSlots(data.slots)
    } catch {
      this.slotsTarget.innerHTML = '<p class="text-sm text-red-500">Failed to load available times</p>'
    }
  }

  renderSlots(slots) {
    const container = this.slotsTarget
    container.innerHTML = ""

    if (slots.length === 0) {
      container.innerHTML = '<p class="text-sm text-gray-500">No available times for this date</p>'
      return
    }

    slots.forEach(slot => {
      const btn = document.createElement("button")
      btn.type = "button"
      const startTime = new Date(slot.start_time)
      btn.textContent = startTime.toLocaleTimeString([], { hour: "numeric", minute: "2-digit", timeZone: this.selectedTimezone })
      btn.className = "block w-full text-left px-4 py-2 text-sm font-medium text-indigo-600 border border-indigo-200 rounded-md hover:bg-indigo-50"
      btn.addEventListener("click", () => this.selectSlot(slot, btn))
      container.appendChild(btn)
    })
  }

  selectSlot(slot, btn) {
    // Highlight selected slot
    this.slotsTarget.querySelectorAll("button").forEach(b => {
      b.className = "block w-full text-left px-4 py-2 text-sm font-medium text-indigo-600 border border-indigo-200 rounded-md hover:bg-indigo-50"
    })
    btn.className = "block w-full text-left px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-indigo-600 rounded-md"

    // Populate hidden fields
    this.startTimeTarget.value = slot.start_time
    this.endTimeTarget.value = slot.end_time
    this.timezoneInputTarget.value = this.selectedTimezone

    // Show booking form
    this.bookingFormTarget.classList.remove("hidden")
  }

  hideBookingForm() {
    this.bookingFormTarget.classList.add("hidden")
  }
}
