import Foundation
import Carbon

struct KeyMapping {
    static func getKeyName(for keyCode: Int) -> String {
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        guard let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData),
              let keyLayout = unsafeBitCast(layoutData, to: CFData.self) as Data? else {
            return getSpecialKeyName(for: keyCode)
        }
        
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        var deadKeyState: UInt32 = 0
        
        // 获取普通字符
        let error = keyLayout.withUnsafeBytes { ptr in
            UCKeyTranslate(
                ptr.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self),
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                4,
                &length,
                &chars
            )
        }
        
        if error == noErr, length > 0 {
            let normalChar = String(utf16CodeUnits: chars, count: Int(length))
            
            // 获取Shift修饰键字符
            chars = [UniChar](repeating: 0, count: 4)
            length = 0
            deadKeyState = 0
            
            let shiftError = keyLayout.withUnsafeBytes { ptr in
                UCKeyTranslate(
                    ptr.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self),
                    UInt16(keyCode),
                    UInt16(kUCKeyActionDisplay),
                    UInt32(shiftKey >> 8),
                    UInt32(LMGetKbdType()),
                    UInt32(kUCKeyTranslateNoDeadKeysBit),
                    &deadKeyState,
                    4,
                    &length,
                    &chars
                )
            }
            
            if shiftError == noErr, length > 0 {
                let shiftChar = String(utf16CodeUnits: chars, count: Int(length))
                if normalChar != shiftChar {
                    return "\(normalChar)/\(shiftChar)"
                }
            }
            
            return normalChar
        }
        
        return getSpecialKeyName(for: keyCode)
    }
    
    private static func getSpecialKeyName(for keyCode: Int) -> String {
        switch keyCode {
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Esc"
        case 55: return "Command"
        case 56: return "Shift"
        case 57: return "Caps Lock"
        case 58: return "Option"
        case 59: return "Control"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key \(keyCode)"
        }
    }
} 