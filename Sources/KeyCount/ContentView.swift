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
    
    enum TimeRange: String, CaseIterable {
        case today = "今天"
        case allTime = "全部"
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
            
            if #available(macOS 13.0, *) {
                ScrollView {
                    Chart {
                        ForEach(stats.filter { $0.count > 0 }.sorted(by: { $0.count > $1.count })) { stat in
                            BarMark(
                                x: .value("次数", stat.count),
                                y: .value("按键", stat.keyName)
                            )
                        }
                    }
                    .frame(height: CGFloat(stats.filter { $0.count > 0 }.count * 25 + 50))
                    .padding()
                }
            } else {
                List {
                    ForEach(stats.sorted(by: { $0.count > $1.count })) { stat in
                        HStack {
                            Text(stat.keyName)
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            Text("\(stat.count)")
                                .monospacedDigit()
                        }
                        .opacity(stat.count > 0 ? 1 : 0.5)
                    }
                }
            }
            
            HStack {
                Button("重置统计") {
                    KeyboardMonitor.shared.resetStats()
                    updateStats()
                }
                .padding()
                
                Button("刷新数据") {
                    updateStats()
                }
                .padding()
            }
        }
        .frame(width: 600, height: 600)
        .onAppear {
            stats = KeyboardLayout.getAllKeys()
            updateStats()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func updateStats() {
        let rawStats = KeyboardMonitor.shared.getStats()
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