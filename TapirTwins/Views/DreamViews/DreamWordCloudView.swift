import SwiftUI
import NaturalLanguage
import UIKit

struct DreamWordCloudView: View {
    @StateObject private var viewModel = DreamWordCloudViewModel()
    @State private var selectedTimeRange: TimeRange = .all
    @State private var startDate = Date().addingTimeInterval(-30*24*60*60) // 默认30天前
    @State private var endDate = Date()
    @State private var showDatePicker = false
    @State private var isCustomRange = false
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case all = "全部"
        case lastWeek = "最近一周"
        case lastMonth = "最近一个月"
        case lastThreeMonths = "最近三个月"
        case custom = "自定义"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 时间范围选择器
                VStack(alignment: .leading) {
                    Text("选择时间范围")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("时间范围", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { newValue in
                        isCustomRange = (newValue == .custom)
                        updateDateRange()
                    }
                    
                    if isCustomRange {
                        HStack {
                            DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(CompactDatePickerStyle())
                            
                            Text("至")
                            
                            DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        .padding(.horizontal)
                        
                        Button("应用") {
                            viewModel.generateWordCloud(dreams: viewModel.filterDreamsByDateRange(startDate: startDate, endDate: endDate))
                        }
                        .padding(.horizontal)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding()
                } else if viewModel.wordFrequencies.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cloud")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("没有足够的梦境数据生成词云")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                } else {
                    // 词云展示
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("共分析了 \(viewModel.analyzedDreamsCount) 条梦境记录")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            WordCloudView(words: viewModel.wordFrequencies)
                                .frame(height: 400)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("梦境词云")
            .onAppear {
                viewModel.fetchDreams()
            }
        }
    }
    
    private func updateDateRange() {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .all:
            // 不需要更新日期，使用所有梦境
            viewModel.generateWordCloud(dreams: viewModel.dreams)
        case .lastWeek:
            let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            viewModel.generateWordCloud(dreams: viewModel.filterDreamsByDateRange(startDate: startDate, endDate: now))
        case .lastMonth:
            let startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            viewModel.generateWordCloud(dreams: viewModel.filterDreamsByDateRange(startDate: startDate, endDate: now))
        case .lastThreeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: now)!
            viewModel.generateWordCloud(dreams: viewModel.filterDreamsByDateRange(startDate: startDate, endDate: now))
        case .custom:
            // 自定义范围时不自动更新，等待用户点击应用按钮
            break
        }
    }
}

struct WordCloudView: View {
    let words: [(String, Double)]
    
    var body: some View {
        ZStack {
            ForEach(words.indices, id: \.self) { index in
                Text(words[index].0)
                    .font(.system(size: CGFloat(words[index].1 * 30 + 12)))
                    .foregroundColor(Color(
                        hue: Double.random(in: 0.5...0.7),
                        saturation: Double.random(in: 0.5...0.8),
                        brightness: Double.random(in: 0.7...0.9)
                    ))
                    .position(
                        x: CGFloat.random(in: 50...300),
                        y: CGFloat.random(in: 50...350)
                    )
                    .rotationEffect(.degrees(Double.random(in: -30...30)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct DreamWordCloudView_Previews: PreviewProvider {
    static var previews: some View {
        DreamWordCloudView()
    }
} 