//
//  Scrabble3App.swift
//  Scrabble3
//
//  Created by Alex on 1/9/23.
//

import SwiftUI
import Firebase

@main
struct Scrabble3App: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var authEmailViewModel = AuthWithEmailViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authEmailViewModel)
                .modifier(ErrorAlert())
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }
}
