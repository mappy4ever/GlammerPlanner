import EventKit
import Foundation

@Observable
final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()
    var hasAccess = false
    var calendars: [EKCalendar] = []
    var events: [EKEvent] = []

    private init() {
        // Check if we already have authorization from a previous launch
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess || status == .authorized {
            hasAccess = true
            loadCalendars()
        }
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        // Already have access from this session — skip everything
        if hasAccess { return true }

        // Check system authorization status
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess || status == .authorized {
            await MainActor.run { hasAccess = true }
            loadCalendars()
            return true
        }
        do {
            let granted = try await store.requestFullAccessToEvents()
            await MainActor.run { hasAccess = granted }
            if granted { loadCalendars() }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    // MARK: - Calendars

    func loadCalendars() {
        calendars = store.calendars(for: .event)
    }

    // MARK: - Events

    func fetchEvents(from start: Date, to end: Date) -> [EKEvent] {
        guard hasAccess else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let fetched = store.events(matching: predicate)
        events = fetched
        return fetched
    }

    func fetchEventsForDay(_ date: Date) -> [EKEvent] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return fetchEvents(from: start, to: end)
    }

    func fetchEventsForMonth(containing date: Date) -> [EKEvent] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: date)),
              let end = cal.date(byAdding: .day, value: range.count, to: start)
        else { return [] }
        return fetchEvents(from: start, to: end)
    }

    // MARK: - Create / Update / Delete

    func createEvent(title: String, startDate: Date, endDate: Date?, notes: String?) -> String? {
        guard hasAccess else { return nil }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        do {
            try store.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Save event error: \(error)")
            return nil
        }
    }

    func deleteEvent(identifier: String) {
        guard hasAccess,
              let event = store.event(withIdentifier: identifier)
        else { return }
        do {
            try store.remove(event, span: .thisEvent)
        } catch {
            print("Delete event error: \(error)")
        }
    }

    func eventsGroupedByDay(for month: Date) -> [Date: [EKEvent]] {
        let events = fetchEventsForMonth(containing: month)
        let cal = Calendar.current
        return Dictionary(grouping: events) { cal.startOfDay(for: $0.startDate) }
    }
}
