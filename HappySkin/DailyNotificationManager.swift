//
//  DailyNotificationManager.swift
//  HappySkin
//

import Foundation
import UserNotifications

final class DailyNotificationManager {
    static let shared = DailyNotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "daily-skin-reminder-"

    private let orderedMessages = [
        "Un escaneo al día, piel feliz",
        "2 segundos y tu piel te lo agradece",
        "Tu rutina te está esperando"
    ]

    private init() {}

    func configureDailyReminders() {
        Task {
            let isAuthorized = await requestAuthorizationIfNeeded()
            guard isAuthorized else { return }
            await scheduleOrderedDailyReminders(daysToSchedule: 60, hour: 20, minute: 0)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await requestAuthorization()
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: granted)
            }
        }
    }

    private func scheduleOrderedDailyReminders(daysToSchedule: Int, hour: Int, minute: Int) async {
        let existingRequests = await pendingNotificationRequests()
        let idsToRemove = existingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }

        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }

        guard let firstReminderDate = nextReminderDate(hour: hour, minute: minute) else { return }

        for dayOffset in 0..<daysToSchedule {
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: firstReminderDate) else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "HappySkin"
            content.body = orderedMessages[dayOffset % orderedMessages.count]
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(identifierPrefix)\(dayOffset)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            await add(request)
        }
    }

    private func pendingNotificationRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private func add(_ request: UNNotificationRequest) async {
        await withCheckedContinuation { continuation in
            center.add(request) { _ in
                continuation.resume(returning: ())
            }
        }
    }

    private func nextReminderDate(hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = hour
        todayComponents.minute = minute
        todayComponents.second = 0

        guard let reminderToday = calendar.date(from: todayComponents) else { return nil }

        if reminderToday > now {
            return reminderToday
        }

        return calendar.date(byAdding: .day, value: 1, to: reminderToday)
    }
}
