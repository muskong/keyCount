import Foundation
import Carbon

class KeyboardMonitor {
    static let shared = KeyboardMonitor()
    private var keyStats: [Int: Int] = [:] // keyCode: count
    
    private init() {}
    
    func startMonitoring() {
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                KeyboardMonitor.shared.handleKeyEvent(event)
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        ) else {
            print("Failed to create event tap")
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        DispatchQueue.global(qos: .background).async {
            CFRunLoopRun()
        }
    }
    
    private func handleKeyEvent(_ event: CGEvent) {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        keyStats[keyCode, default: 0] += 1
        saveStats()
    }
    
    private func saveStats() {
        let defaults = UserDefaults.standard
        defaults.set(keyStats, forKey: "KeyStats")
    }
    
    func getStats() -> [Int: Int] {
        return keyStats
    }
    
    func resetStats() {
        keyStats.removeAll()
        saveStats()
    }
    
    func loadStats() {
        if let savedStats = UserDefaults.standard.dictionary(forKey: "KeyStats") as? [Int: Int] {
            keyStats = savedStats
        }
    }
} 