import AppKit
import UserNotifications

@MainActor
public enum BellNotifications {
  public static func setEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: "bellNotifications")
    if enabled {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
        granted, _ in
        if !granted { UserDefaults.standard.set(false, forKey: "bellNotifications") }
      }
    }
  }
  public static func deliver() {
    guard !NSApp.isActive, UserDefaults.standard.bool(forKey: "bellNotifications") else { return }
    let content = UNMutableNotificationContent()
    content.title = "Specter"
    content.body = "A terminal session rang the bell."
    UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: "specter-terminal-bell", content: content, trigger: nil))
  }
}
