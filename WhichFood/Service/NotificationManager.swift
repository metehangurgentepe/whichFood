//
//  NotificationManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.01.2025.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    init() {
        setupNotificationCategories()
    }
    
    private func setupNotificationCategories() {
        let viewInMapsAction = UNNotificationAction(
            identifier: "VIEW_IN_MAPS",
            title: "View in Maps",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "PARKING_REMINDER",
            actions: [viewInMapsAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                self.setupNotificationCategories()
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleTimeBasedNotification(at date: Date, title: String, body: String, userInfo: [String: Any]? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling time-based notification: \(error)")
            }
        }
    }
    
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
