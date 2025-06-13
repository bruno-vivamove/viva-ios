import SwiftUI
import FirebaseCore

class FirebaseUtil {
    public static func configureFirebase() {
        // Read the file name from the Info.plist
        guard let plistFileName = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_CONFIG_FILE") as? String else {
            // Fallback for safety, though this should not happen in a correctly configured project
            FirebaseApp.configure()
            AppLogger.error("FIREBASE_CONFIG_FILE not found in Info.plist. Falling back to default Firebase configuration.", category: .general)
            return
        }
        
        // Load the corresponding plist file
        if let filePath = Bundle.main.path(forResource: plistFileName, ofType: "plist"),
           let firebaseOptions = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: firebaseOptions)
            AppLogger.info("Firebase configured using \(plistFileName).plist.", category: .general)
        } else {
            // Fallback to default configuration if specific file is not found
            FirebaseApp.configure()
            AppLogger.warning("Could not find \(plistFileName).plist. Falling back to default Firebase configuration.", category: .general)
        }
    }
}
