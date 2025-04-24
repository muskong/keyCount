import Foundation
import Carbon

class KeyboardMonitor {
    static let shared = KeyboardMonitor()
    private var keyStats: [Int: Int] = [:] // keyCode: count
    private var eventTap: CFMachPort?
    
    private init() {
        loadStats()
    }
    
    func startMonitoring() {
        // 检查辅助功能权限
        let trusted = checkAccessibilityPermissions()
        guard trusted else {
            print("需要辅助功能权限来监听键盘事件")
            return
        }
        
        // 监听按键按下和修饰键事件
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue |
                                  1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap, // 在系统处理完事件后再处理
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                KeyboardMonitor.shared.handleKeyEvent(event, type: type)
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        ) else {
            print("无法创建事件监听")
            return
        }
        
        self.eventTap = eventTap
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        DispatchQueue.global(qos: .utility).async { // 使用 utility 优先级避免影响主线程
            CFRunLoopRun()
        }
    }
    
    func stopMonitoring() {
        if let eventTap = self.eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }
    
    private func handleKeyEvent(_ event: CGEvent, type: CGEventType) {
        switch type {
        case .keyDown:
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            keyStats[keyCode, default: 0] += 1
            saveStats()
        case .flagsChanged:
            // 处理修饰键（如 Shift、Control 等）
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags
            
            // 只在修饰键按下时计数
            if !flags.isEmpty {
                keyStats[keyCode, default: 0] += 1
                saveStats()
            }
        default:
            break
        }
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func saveStats() {
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