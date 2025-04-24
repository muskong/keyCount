import SwiftUI
import Carbon

@main
struct KeyCountApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) { }
            CommandGroup(replacing: .windowList) { }
            
            // 添加自定义命令
            CommandMenu("文件") {
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }.keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        KeyboardMonitor.shared.startMonitoring()
        
        // 加载保存的统计数据
        KeyboardMonitor.shared.loadStats()
        
        // 注册全局快捷键
        registerGlobalHotkeys()
        
        // 直接显示统计窗口
        showStats()
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyCount")
        }
        
        let menu = NSMenu()
        menu.addItem(withTitle: "显示统计", action: #selector(showStats), keyEquivalent: "s")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q")
        
        statusItem?.menu = menu
    }
    
    private func registerGlobalHotkeys() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
                self.quit()
                return nil
            }
            return event
        }
    }
    
    @objc private func showStats() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            let contentView = ContentView()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window?.title = "键盘输入统计"
            window?.contentView = NSHostingView(rootView: contentView)
            window?.center()
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // 设置窗口代理以处理关闭事件
            window?.delegate = self
        }
    }
    
    @objc private func quit() {
        KeyboardMonitor.shared.saveStats()
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 保存统计数据
        KeyboardMonitor.shared.saveStats()
    }
}

// 添加窗口代理扩展
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // 窗口关闭时只是隐藏，不退出应用
        window = nil
    }
} 