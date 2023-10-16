//
//  LocalNotificationManager.swift
//  HAPTIC-XCEL Watch App
//
//  Created by Oleg Golev on 10/15/23.
//

import Foundation
import UserNotifications

struct Notification {
    var title: String
    var body: String
}

class LocalNotificationManager {
    
    private func listScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { notifications in
            for notification in notifications {
                print(notification)
            }
        }
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted == true && error == nil {
                return
            } else {
                print("ERROR: user did not grant proper notification permissions.")
            }
        }
    }
    
    func schedule(notification: Notification) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization()
            case .authorized, .provisional:
                self.scheduleNotification(notification: notification)
            default:
                break
            }
        }
    }
    
    private func scheduleNotification(notification: Notification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                print("ERROR: failed to add notification request.")
            } else {
                print("Notification scheduled.")
            }
        }
        listScheduledNotifications()
    }
}
