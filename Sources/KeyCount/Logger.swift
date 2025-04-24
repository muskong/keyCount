import Foundation

class Logger {
    static let shared = Logger()
    private let dateFormatter: DateFormatter
    private let fileManager = FileManager.default
    private let logsDirectory: URL
    private var currentLogFile: URL?
    private let queue = DispatchQueue(label: "com.keycount.logger")
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 获取应用支持目录
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("无法获取应用支持目录")
        }
        
        // 创建KeyCount目录
        let keyCountDir = appSupport.appendingPathComponent("KeyCount")
        if !fileManager.fileExists(atPath: keyCountDir.path) {
            try? fileManager.createDirectory(at: keyCountDir, withIntermediateDirectories: true)
        }
        
        // 创建logs目录
        logsDirectory = keyCountDir.appendingPathComponent("logs")
        if !fileManager.fileExists(atPath: logsDirectory.path) {
            try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func getCurrentLogFile() -> URL {
        let today = dateFormatter.string(from: Date())
        return logsDirectory.appendingPathComponent("\(today).log")
    }
    
    func log(_ message: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let logFile = self.getCurrentLogFile()
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let logMessage = "\(timestamp) \(message)\n"
            
            if !self.fileManager.fileExists(atPath: logFile.path) {
                try? logMessage.write(to: logFile, atomically: true, encoding: .utf8)
            } else {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    if let data = logMessage.data(using: .utf8) {
                        handle.write(data)
                    }
                    try? handle.close()
                }
            }
        }
    }
    
    func getLogFiles() -> [URL] {
        (try? fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)) ?? []
    }
    
    func clearOldLogs(olderThan days: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let logFiles = self.getLogFiles()
            for logFile in logFiles {
                if let attributes = try? self.fileManager.attributesOfItem(atPath: logFile.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try? self.fileManager.removeItem(at: logFile)
                }
            }
        }
    }
} 