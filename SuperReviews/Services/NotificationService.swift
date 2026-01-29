import Foundation
import AppKit
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error = error {
                print("❌ Error requesting notification permission: \(error)")
            }
            print("🔔 Notification permission granted: \(granted)")
            self?.checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            self?.authorizationStatus = settings.authorizationStatus
            print("🔔 Notification authorization status: \(settings.authorizationStatus.rawValue) (0=notDetermined, 1=denied, 2=authorized)")
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            print("🔔 Notification status check: \(isAuthorized ? "ON" : "OFF") (status: \(settings.authorizationStatus.rawValue))")
            completion(isAuthorized)
        }
    }
    
    func isAuthorized() -> Bool {
        return authorizationStatus == .authorized
    }
    
    func sendNotification(title: String, body: String, url: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["url": url]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error sending notification: \(error)")
            } else {
                print("✅ Notification sent: \(title)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // User clicked on notification
        if let urlString = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
