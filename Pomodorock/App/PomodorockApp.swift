//
//  PomodorockApp.swift
//  Pomodorock
//
//  Created by Lulu_Lee on 2026/7/26.
//

import SwiftUI

#if canImport(FirebaseCore)
    import FirebaseCore
#endif

#if os(iOS) && canImport(FirebaseCore)
    import UIKit

    // Firebase 官方建議：在 App 啟動時 configure
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication
                .LaunchOptionsKey: Any]? = nil
        ) -> Bool {
            FirebaseApp.configure()
            return true
        }
    }
#endif

@main
struct PomodorockApp: App {
    #if os(iOS) && canImport(FirebaseCore)
        // iOS：透過 AppDelegate 完成 Firebase 設定
        @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @State private var quoteStore: QuoteStore
    @State private var userStore: UserStore

    init() {
        // 非 iOS 平台沒有 UIApplicationDelegate，改在此 configure
        #if !os(iOS) && canImport(FirebaseCore)
            FirebaseApp.configure()
        #endif

        #if canImport(FirebaseFirestore)
            _quoteStore = State(
                initialValue: QuoteStore(remoteService: FirestoreQuoteService())
            )
        #else
            _quoteStore = State(initialValue: QuoteStore())
        #endif

        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
            _userStore = State(
                initialValue: UserStore(sync: FirebaseUserSyncService())
            )
        #else
            _userStore = State(
                initialValue: UserStore(sync: LocalUserSyncService())
            )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(quoteStore)
                .environment(userStore)
        }
    }
}
