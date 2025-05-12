import SwiftUI
import Firebase

@main
struct SwypApp2ndApp: App {
    
    init() {
        NotificationManager.shared.requestPermissionIfNeeded()
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
