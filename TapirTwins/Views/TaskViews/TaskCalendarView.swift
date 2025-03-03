import SwiftUI

struct TaskCalendarView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMonth: Date = Date()
    
    // 定义主题颜色，与TaskListView保持一致
    private let themeColor = Color(red: 0.96, green: 0.76, blue: 0.86) // 柔和的粉色
    private let themeColorDark = Color(red: 0.9, green: 0.5, blue: 0.7) // 深一点的粉色
    private let themeColorLight = Color(red: 0.98, green: 0.86, blue: 0.92) // 浅一点的粉色
    private let themeGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.98, green: 0.86, blue: 0.92),
            Color(red: 0.96, green: 0.76, blue: 0.86)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                themeGradient
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 月份选择器
                    HStack {
                        Button(action: {
                            withAnimation {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                                loadMonthData()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(themeColorDark)
                                .padding()
                        }
                        
                        Spacer()
                        
                        Text(monthFormatter.string(from: selectedMonth))
                            .font(.title2)
                            .bold()
                            .foregroundColor(themeColorDark)
                        
                        Spacer()
                        
                        Button(action: {
                            let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                            if nextMonth <= Date() { // 只允许选择当前月及之前的月份
                                withAnimation {
                                    selectedMonth = nextMonth
                                    loadMonthData()
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)! <= Date() ? themeColorDark : Color.gray.opacity(0.5))
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    // 星期标题
                    HStack {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(themeColorDark)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 日历部分
                    if viewModel.isLoadingStats {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeColorDark))
                            .scaleEffect(1.5)
                        Spacer()
                    } else {
                        calendarGrid
                            .padding(.horizontal)
                        
                        // 颜色图例
                        HStack(spacing: 15) {
                            legendItem(color: .green, text: "全部打卡成功")
                            legendItem(color: .orange, text: "1-2个未打卡")
                            legendItem(color: .red, text: "3个及以上未打卡")
                        }
                        .padding()
                        
                        Text("统计数据每日0点30分更新")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("任务统计日历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("关闭")
                            .foregroundColor(themeColorDark)
                    }
                }
            }
            .onAppear {
                loadMonthData()
            }
        }
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(getCalendarDays(), id: \.id) { day in
                if day.dayOfMonth != 0 {
                    Button(action: {}) {
                        VStack {
                            Text("\(day.dayOfMonth)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(day.isToday ? .white : .primary)
                            
                            if let count = day.failedTasksCount {
                                Text("\(count)")
                                    .font(.system(size: 10))
                                    .foregroundColor(day.isToday ? .white : getCountColor(count).opacity(0.8))
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if day.isToday {
                                    Circle()
                                        .fill(themeColorDark)
                                } else if day.failedTasksCount != nil {
                                    Circle()
                                        .fill(getCountColor(day.failedTasksCount!))
                                        .opacity(0.3)
                                }
                            }
                        )
                    }
                    .disabled(true)
                } else {
                    // 空白日期占位符
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .opacity(0.3)
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func getCountColor(_ count: Int) -> Color {
        if count == 0 {
            return .green
        } else if count <= 2 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func loadMonthData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthString = formatter.string(from: selectedMonth)
        
        viewModel.fetchMonthlyTaskStats(month: monthString) { _ in
            // 加载完成后无需特殊处理
        }
    }
    
    private func getCalendarDays() -> [CalendarDay] {
        var days: [CalendarDay] = []
        
        let calendar = Calendar.current
        
        // 当前选中月的第一天
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        
        // 这个月的第一天是星期几（0是星期日，1是星期一，以此类推）
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // 添加上个月的占位日期
        for _ in 0..<firstWeekday {
            days.append(CalendarDay(id: UUID().uuidString, date: Date(), dayOfMonth: 0, isToday: false, failedTasksCount: nil))
        }
        
        // 当前月的天数
        let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        
        // 获取今天的日期组件
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        let selectedMonthComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
        
        // 添加当月的日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for day in 1...numberOfDaysInMonth {
            var dateComponents = DateComponents()
            dateComponents.year = selectedMonthComponents.year
            dateComponents.month = selectedMonthComponents.month
            dateComponents.day = day
            
            let date = calendar.date(from: dateComponents)!
            let dateString = dateFormatter.string(from: date)
            
            // 检查是否是今天
            let isToday = todayComponents.year == dateComponents.year &&
                          todayComponents.month == dateComponents.month &&
                          todayComponents.day == dateComponents.day
            
            // 获取该日期的统计数据
            let failedCount = viewModel.monthlyTaskStats?.dailyStats.first(where: { $0.date == dateString })?.failedTasksCount
            
            // 仅为当前日期之前的日期添加统计数据
            let displayCount = date <= Date() ? failedCount : nil
            
            days.append(CalendarDay(
                id: UUID().uuidString,
                date: date,
                dayOfMonth: day,
                isToday: isToday,
                failedTasksCount: displayCount
            ))
        }
        
        return days
    }
}

// 用于日历显示的日期结构
struct CalendarDay: Identifiable {
    let id: String
    let date: Date
    let dayOfMonth: Int
    let isToday: Bool
    let failedTasksCount: Int?
}

struct TaskCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        TaskCalendarView(viewModel: TaskViewModel())
    }
} 