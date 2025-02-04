import UIKit

import Flutter

//added by Kornel
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    //added by Kornel
      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback{ (registry) in GeneratedPluginRegistrant.register(with: registry) }

    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self

    return true
  }

    // Delegate method to handle foreground notification
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge]) // Modify this based on your needs
    }

}
