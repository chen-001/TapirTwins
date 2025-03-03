import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddSheet = false
    @State private var showingCalendarSheet = false
    @State private var searchText = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 定义主题颜色
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
    
    var filteredTasks: [TapirTask] {
        if searchText.isEmpty {
            return viewModel.tasks
        } else {
            return viewModel.tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                themeGradient
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeColorDark))
                        .scaleEffect(1.5)
                } else if viewModel.tasks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(themeColorDark)
                        
                        Text("暂无任务")
                            .font(.title2)
                            .foregroundColor(themeColorDark)
                        
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Text("添加任务")
                                .bold()
                                .frame(width: 200)
                                .padding()
                                .background(themeColorDark)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        // 搜索栏已由.searchable修饰符提供
                        
                        List {
                            ForEach(filteredTasks) { task in
                                NavigationLink(destination: TaskDetailView(task: task, viewModel: viewModel)
                                    .environmentObject(authViewModel)) {
                                    TaskRow(task: task, themeColor: themeColorDark)
                                }
                                .listRowBackground(Color.white.opacity(0.7))
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .refreshable {
                            viewModel.fetchTasks()
                        }
                    }
                }
            }
            .navigationTitle("任务")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingCalendarSheet = true
                    }) {
                        Image(systemName: "calendar")
                            .foregroundColor(themeColorDark)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(themeColorDark)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationView {
                    TaskFormView(mode: .add, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingCalendarSheet) {
                TaskCalendarView(viewModel: viewModel)
            }
            .searchable(text: $searchText, prompt: "搜索任务")
            .accentColor(themeColorDark) // 设置搜索栏和其他交互元素的强调色
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("错误"),
                    message: Text(viewModel.errorMessage ?? "未知错误"),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
        .onAppear {
            viewModel.fetchTasks()
        }
        .accentColor(themeColorDark) // 设置导航栏和其他交互元素的强调色
    }
}

struct TaskRow: View {
    let task: TapirTask
    let themeColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: task.completedToday ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completedToday ? themeColor : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.completedToday)
                        .foregroundColor(task.completedToday ? .gray : .primary)
                    
                    Spacer()
                    
                    // 添加空间任务标签
                    if task.spaceId != nil {
                        Text("空间")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(themeColor.opacity(0.8))
                            Text(formatDate(dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "photo.stack")
                            .font(.caption)
                            .foregroundColor(themeColor.opacity(0.8))
                        Text("\(task.requiredImages)张图片")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    if let status = task.status, status != .pending {
                        HStack(spacing: 4) {
                            Image(systemName: statusIcon(for: status))
                                .font(.caption)
                                .foregroundColor(statusColor(for: status))
                            Text(statusText(for: status))
                                .font(.caption)
                                .foregroundColor(statusColor(for: status))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func statusIcon(for status: TaskStatus) -> String {
        switch status {
        case .submitted:
            return "hourglass"
        case .approved:
            return "checkmark.seal.fill"
        case .rejected:
            return "xmark.seal.fill"
        case .pending:
            return "circle"
        }
    }
    
    private func statusText(for status: TaskStatus) -> String {
        switch status {
        case .submitted:
            return "已提交"
        case .approved:
            return "已通过"
        case .rejected:
            return "已拒绝"
        case .pending:
            return "待完成"
        }
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .submitted:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        case .pending:
            return .gray
        }
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
    }
}
