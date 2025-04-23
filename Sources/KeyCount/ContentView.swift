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
    
    var body: some View {
        VStack {
            Text("键盘输入统计")
                .font(.title)
                .padding()
            
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(stats.sorted(by: { $0.count > $1.count }).prefix(20)) { stat in
                        BarMark(
                            x: .value("次数", stat.count),
                            y: .value("按键", stat.keyName)
                        )
                    }
                }
                .frame(height: 400)
                .padding()
            } else {
                List(stats.sorted(by: { $0.count > $1.count })) { stat in
                    HStack {
                        Text(stat.keyName)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Text("次数: \(stat.count)")
                    }
                }
                .frame(height: 400)
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
        .frame(width: 600, height: 500)
        .onAppear {
            updateStats()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func updateStats() {
        let rawStats = KeyboardMonitor.shared.getStats()
        stats = rawStats.map { keyCode, count in
            KeyStatItem(
                id: keyCode,
                keyCode: keyCode,
                keyName: KeyMapping.getKeyName(for: keyCode),
                count: count
            )
        }
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