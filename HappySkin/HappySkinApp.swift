//
//  HappySkinApp.swift
//  HappySkin
//
//  Created by Abraham Castañeda Quintero on 14/04/26.
//

import SwiftUI
import SwiftData
import FirebaseCore
#if canImport(FacebookCore)
import FacebookCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FacebookLogin)
import FacebookLogin
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        DailyNotificationManager.shared.configureDailyReminders()
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(
            UIOffset(horizontal: -1000, vertical: 0),
            for: .default
        )
#if canImport(FacebookCore)
    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
#endif
        return true
    }

    func application(_ app: UIApplication,
             open url: URL,
             options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    var handled = false
    #if canImport(FacebookCore)
    handled = ApplicationDelegate.shared.application(app, open: url, options: options)
#endif
#if canImport(GoogleSignIn)
    handled = GIDSignIn.sharedInstance.handle(url) || handled
#endif
    return handled
    }
}
#endif

@main
struct HappySkinApp: App {
#if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
#endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: "es_MX"))
        }
        .modelContainer(sharedModelContainer)
    }
}
