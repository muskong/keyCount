import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    
    // 定义表和列
    private let keyStats = Table("key_stats")
    private let id = Expression<Int64>("id")
    private let keyCode = Expression<Int>("key_code")
    private let count = Expression<Int>("count")
    private let lastUpdated = Expression<Date>("last_updated")
    private let date = Expression<Date>("date")
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            // 获取应用支持目录
            guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return
            }
            
            // 创建KeyCount目录
            let dbDirectory = appSupport.appendingPathComponent("KeyCount")
            if !FileManager.default.fileExists(atPath: dbDirectory.path) {
                try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
            }
            
            // 数据库文件路径
            let dbPath = dbDirectory.appendingPathComponent("keycount.sqlite").path
            db = try Connection(dbPath)
            
            // 创建表
            try db?.run(keyStats.create(ifNotExists: true) { table in
                table.column(id, primaryKey: .autoincrement)
                table.column(keyCode)
                table.column(count)
                table.column(lastUpdated)
                table.column(date)
                
                // 创建复合唯一索引
                table.uniqueKey([keyCode, date])
            })
            
        } catch {
            print("数据库设置错误: \(error)")
        }
    }
    
    func incrementKeyCount(_ keyCode: Int) {
        guard let db = db else { return }
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            
            // 尝试更新现有记录
            let record = keyStats.filter(self.keyCode == keyCode && date == today)
            let count = try db.pluck(record)
            
            if let existingCount = count {
                // 更新现有记录
                try db.run(record.update(
                    self.count += 1,
                    lastUpdated <- Date()
                ))
            } else {
                // 插入新记录
                try db.run(keyStats.insert(
                    self.keyCode <- keyCode,
                    self.count <- 1,
                    lastUpdated <- Date(),
                    date <- today
                ))
            }
        } catch {
            print("更新按键计数错误: \(error)")
        }
    }
    
    func getStats(timeRange: TimeRange = .today) -> [Int: Int] {
        guard let db = db else { return [:] }
        var stats: [Int: Int] = [:]
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            var query = keyStats
            
            switch timeRange {
            case .today:
                query = query.filter(date == today)
            case .allTime:
                break
            }
            
            // 按keyCode分组并汇总count
            let rows = try db.prepare(query)
            for row in rows {
                let keyCode = row[self.keyCode]
                let count = row[self.count]
                stats[keyCode, default: 0] += count
            }
        } catch {
            print("获取统计数据错误: \(error)")
        }
        
        return stats
    }
    
    func resetStats() {
        guard let db = db else { return }
        
        do {
            try db.run(keyStats.delete())
        } catch {
            print("重置统计数据错误: \(error)")
        }
    }
    
    func cleanupOldData(olderThan days: Int) {
        guard let db = db else { return }
        
        do {
            let calendar = Calendar.current
            guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return }
            
            let oldRecords = keyStats.filter(date < cutoffDate)
            try db.run(oldRecords.delete())
        } catch {
            print("清理旧数据错误: \(error)")
        }
    }
} 