import Foundation

struct KeyboardLayout {
    static let standardKeys: [(Int, String)] = [
        // 数字键
        (18, "1"), (19, "2"), (20, "3"), (21, "4"), (23, "5"),
        (22, "6"), (26, "7"), (28, "8"), (25, "9"), (29, "0"),
        
        // 字母键第一行
        (12, "Q"), (13, "W"), (14, "E"), (15, "R"), (17, "T"),
        (16, "Y"), (32, "U"), (34, "I"), (31, "O"), (35, "P"),
        
        // 字母键第二行
        (0, "A"), (1, "S"), (2, "D"), (3, "F"), (5, "G"),
        (4, "H"), (38, "J"), (40, "K"), (37, "L"),
        
        // 字母键第三行
        (6, "Z"), (7, "X"), (8, "C"), (9, "V"), (11, "B"),
        (45, "N"), (46, "M"),
        
        // 功能键
        (53, "Esc"), (48, "Tab"), (36, "Return"), (49, "Space"),
        (51, "Delete"), (117, "Delete Forward"),
        
        // 修饰键
        (56, "Shift"), (57, "Caps Lock"), (58, "Option"),
        (59, "Control"), (55, "Command"),
        
        // 方向键
        (123, "←"), (124, "→"), (125, "↓"), (126, "↑"),
        
        // 其他常用键
        (24, "="), (27, "-"), (33, "["), (30, "]"),
        (41, ";"), (39, "'"), (43, ","), (47, "."), (44, "/"),
        (42, "\\")
    ]
    
    static func getAllKeys() -> [KeyStatItem] {
        return standardKeys.map { keyCode, name in
            KeyStatItem(
                id: keyCode,
                keyCode: keyCode,
                keyName: name,
                count: 0
            )
        }
    }
} 