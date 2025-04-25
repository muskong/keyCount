import SwiftUI
import Charts

struct KeyStatItem: Identifiable {
    let id: Int
    let keyCode: Int
    let keyName: String
    let count: Int
}

struct ContentView: View {
    @State private var stats: [KeyStatItem] = []
    @State private var timer: Timer?
    @State private var totalKeystrokes: Int = 0
    @State private var selectedTimeRange: TimeRange = .today
    @State private var searchText: String = ""
    @State private var showingCleanupAlert = false
    @State private var cleanupDays: Int = 30
    @State private var showingCleanupConfirmation = false
    
    var filteredStats: [KeyStatItem] {
        if searchText.isEmpty {
            return stats.filter { $0.count > 0 }
        } else {
            return stats.filter { $0.count > 0 && $0.keyName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("键盘输入统计")
                    .font(.title)
                Spacer()
                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            .padding()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("总按键次数：\(totalKeystrokes)")
                        .font(.headline)
                    Text("平均每分钟：\(calculateAverageKeystrokes())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索按键", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            
            // 按键统计列表
            List {
                ForEach(filteredStats.sorted(by: { $0.count > $1.count })) { stat in
                    HStack {
                        Text(stat.keyName)
                            .frame(width: 100, alignment: .leading)
                            .font(.system(.body, design: .monospaced))
                        
                        // 进度条
                        GeometryReader { geometry in
                            let maxCount = filteredStats.map { $0.count }.max() ?? 1
                            let width = CGFloat(stat.count) / CGFloat(maxCount) * geometry.size.width
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: width)
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 20)
                        
                        // 次数
                        Text("\(stat.count)")
                            .frame(width: 80, alignment: .trailing)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(PlainListStyle())
            
            HStack {
                Button("重置统计") {
                    showingCleanupConfirmation = true
                }
                .padding()
                
                Button("清理数据") {
                    showingCleanupAlert = true
                }
                .padding()
                
                Button("刷新数据") {
                    updateStats()
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            stats = KeyboardLayout.getAllKeys()
            updateStats()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        // 清理数据对话框
        .alert("清理历史数据", isPresented: $showingCleanupAlert) {
            TextField("保留天数", value: $cleanupDays, formatter: NumberFormatter())
            Button("取消", role: .cancel) { }
            Button("清理") {
                DatabaseManager.shared.cleanupOldData(olderThan: cleanupDays)
                updateStats()
            }
        } message: {
            Text("请输入要保留的天数，将删除此天数之前的所有数据")
        }
        // 重置确认对话框
        .alert("确认重置", isPresented: $showingCleanupConfirmation) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                KeyboardMonitor.shared.resetStats()
                updateStats()
            }
        } message: {
            Text("确定要重置所有统计数据吗？此操作不可恢复。")
        }
    }
    
    private func updateStats() {
        let rawStats = KeyboardMonitor.shared.getStats(timeRange: selectedTimeRange)
        stats = KeyboardLayout.getAllKeys().map { item in
            KeyStatItem(
                id: item.id,
                keyCode: item.keyCode,
                keyName: item.keyName,
                count: rawStats[item.keyCode] ?? 0
            )
        }
        totalKeystrokes = stats.reduce(0) { $0 + $1.count }
    }
    
    private func calculateAverageKeystrokes() -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let secondsInDay = now.timeIntervalSince(startOfDay)
        let minutesActive = max(1, Int(secondsInDay / 60))
        let average = Double(totalKeystrokes) / Double(minutesActive)
        return String(format: "%.1f", average)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateStats()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
} 