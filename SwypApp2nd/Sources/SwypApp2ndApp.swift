import SwiftUI

@main
struct SwypApp2ndApp: App {
    
    init() {
            NotificationManager.shared.requestPermissionIfNeeded()
        }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
