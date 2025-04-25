import Foundation

enum AppConfig {
    static let bundleIdentifier = "com.keycount.app"
    static let bundleName = "KeyCount"
    static let bundleVersion = "1.0"
    static let buildVersion = "1"
    static let minimumSystemVersion = "12.0"
    static let isBackgroundOnly = false
    static let isUIElement = true
    static let isHighResolutionCapable = true
    static let bundleIconFile = "AppIcon"
    
    static var privilegedHelperIdentifier: String {
        "com.keycount.helper"
    }
    
    static var privilegedHelperRequirement: String {
        "identifier \"com.keycount.helper\" and anchor apple generic and certificate leaf[subject.CN] = \"Apple Development\""
    }
} 