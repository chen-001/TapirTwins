import SwiftUI
import Combine
import Foundation
import UIKit  // 添加UIKit导入，因为在FullScreenImageView中使用了UIImage

// 定义主题颜色为顶级常量
fileprivate let themeColor = Color(red: 0.96, green: 0.76, blue: 0.86) // 柔和的粉色
fileprivate let themeColorDark = Color(red: 0.9, green: 0.5, blue: 0.7) // 深一点的粉色
fileprivate let themeColorLight = Color(red: 0.98, green: 0.86, blue: 0.92) // 浅一点的粉色
fileprivate let themeGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.98, green: 0.86, blue: 0.92),
        Color(red: 0.96, green: 0.76, blue: 0.86)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// 添加可以支持选中图片URL的扩展
extension String: Identifiable {
    public var id: String {
        self
    }
}

struct TaskDetailView: View {
    let task: TapirTask
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCompleteView = false
    @State private var isLoadingRecords = false
    @State private var showingApproveAlert = false
    @State private var showingRejectAlert = false
    @State private var rejectReason = ""
    @State private var selectedRecord: TaskRecord? = nil
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            ZStack {
                // 背景渐变
                themeGradient
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // 任务标题和描述
                    VStack(alignment: .leading, spacing: 10) {
                        Text(task.title)
                            .font(.title)
                            .bold()
                            .foregroundColor(Color.black.opacity(0.8))
                        
                        if let description = task.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(Color.black.opacity(0.7))
                        }
                        
                        if let dueDate = task.dueDate {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(themeColorDark)
                                Text("截止日期: \(formatDate(dueDate))")
                                    .font(.subheadline)
                                    .foregroundColor(Color.black.opacity(0.6))
                            }
                            .padding(.top, 2)
                        }
                        
                        HStack {
                            Image(systemName: "photo.stack")
                                .foregroundColor(themeColorDark)
                            Text("需要图片: \(task.requiredImages)张")
                                .font(.subheadline)
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                        
                        if let status = task.status, status != .pending {
                            HStack {
                                Image(systemName: statusIcon(for: status))
                                    .foregroundColor(statusColor(for: status))
                                Text("状态: \(statusText(for: status))")
                                    .font(.subheadline)
                                    .foregroundColor(statusColor(for: status))
                            }
                            .padding(.top, 2)
                        }
                        
                        Divider()
                            .background(themeColorDark)
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal)
                    
                    // 任务状态
                    VStack(alignment: .leading, spacing: 10) {
                        Text("任务状态")
                            .font(.headline)
                            .foregroundColor(themeColorDark)
                        
                        HStack {
                            Image(systemName: task.completedToday ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.completedToday ? themeColorDark : .gray)
                                .font(.title2)
                            
                            Text(task.completedToday ? "今日已完成" : "今日未完成")
                                .font(.body)
                                .foregroundColor(task.completedToday ? themeColorDark : .gray)
                            
                            Spacer()
                            
                            if !task.completedToday {
                                Button(action: {
                                    showingCompleteView = true
                                }) {
                                    Text("完成任务")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(themeColorDark)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // 添加空间任务审批按钮（如果是空间任务且状态为已提交）
                    if let spaceId = task.spaceId, let status = task.status, status.rawValue == "submitted" {
                        spaceTaskApprovalView
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    // 历史记录
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("历史记录")
                                .font(.headline)
                                .foregroundColor(themeColorDark)
                            
                            Spacer()
                            
                            if isLoadingRecords {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: themeColorDark))
                            }
                        }
                        
                        if viewModel.taskRecords.isEmpty && !isLoadingRecords {
                            Text("暂无历史记录")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(viewModel.taskRecords) { record in
                                RecordItemView(record: record)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
        }
        .navigationTitle("任务详情")
        .navigationBarItems(trailing: Button(action: {
            showingEditSheet = true
        }) {
            Image(systemName: "pencil")
                .foregroundColor(themeColorDark)
        })
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                TaskFormView(mode: .edit(task), viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingCompleteView) {
            TaskCompleteView(task: task, viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(themeColorDark)
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("删除任务"),
                message: Text("确定要删除这个任务吗？此操作不可撤销。"),
                primaryButton: .destructive(Text("删除"), action: {
                    viewModel.deleteTask(taskId: task.id) { _ in }
                }),
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .alert(isPresented: $showingApproveAlert) {
            Alert(
                title: Text("审批任务"),
                message: Text("确定要批准这个任务吗？"),
                primaryButton: .default(Text("确定"), action: {
                    approveTask()
                }),
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .alert("拒绝任务", isPresented: $showingRejectAlert) {
            TextField("拒绝原因", text: $rejectReason)
            Button("取消", role: .cancel) { }
            Button("确定", role: .destructive) {
                rejectTask()
            }
        } message: {
            Text("请输入拒绝原因")
        }
        .onAppear {
            loadTaskRecords()
        }
    }
    
    // 添加空间任务审批视图
    private var spaceTaskApprovalView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("任务审批")
                .font(.headline)
                .foregroundColor(themeColorDark)
            
            HStack {
                Button(action: {
                    showingApproveAlert = true
                }) {
                    Text("批准")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    showingRejectAlert = true
                }) {
                    Text("拒绝")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // 检查当前用户是否有审批权限
    private func isUserApprover() -> Bool {
        // 简化实现：暂时允许所有用户审批
        // 在实际应用中，应该检查用户是否为指定审批者或有审批权限的角色
        return true
    }
    
    // 批准任务
    private func approveTask() {
        guard let spaceId = task.spaceId, let recordId = getLatestRecordId() else {
            return
        }
        
        viewModel.approveSpaceTaskRecord(spaceId: spaceId, recordId: recordId) { success in
            if success {
                // 刷新任务记录
                loadTaskRecords()
            }
        }
    }
    
    // 拒绝任务
    private func rejectTask() {
        guard let spaceId = task.spaceId, let recordId = getLatestRecordId(), !rejectReason.isEmpty else {
            return
        }
        
        viewModel.rejectSpaceTaskRecord(spaceId: spaceId, recordId: recordId, reason: rejectReason) { success in
            if success {
                // 刷新任务记录
                loadTaskRecords()
                // 清空拒绝原因
                rejectReason = ""
            }
        }
    }
    
    // 获取最新记录ID
    private func getLatestRecordId() -> String? {
        // 如果有选中的记录，使用选中记录的ID
        if let selectedId = selectedRecord?.id {
            print("使用选中的记录ID: \(selectedId)")
            return selectedId
        }
        
        // 否则使用最新的记录ID
        if let latestId = viewModel.taskRecords.first?.id {
            print("使用最新的记录ID: \(latestId)")
            return latestId
        }
        
        print("没有找到可用的记录ID")
        return nil
    }
    
    private func loadTaskRecords() {
        isLoadingRecords = true
        viewModel.fetchTaskRecords(id: task.id)
        
        // 添加延迟回调以确保isLoadingRecords可以被设置为false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoadingRecords = false
            
            // 打印任务记录数量，用于调试
            print("加载到\(self.viewModel.taskRecords.count)条任务记录")
            if let firstRecord = self.viewModel.taskRecords.first {
                print("第一条记录ID: \(firstRecord.id), 状态: \(firstRecord.status)")
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
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

struct RecordItemView: View {
    let record: TaskRecord
    @State private var showingFullScreenImage = false
    @State private var selectedImageURL: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(formatDate(record.createdAt))
                    .font(.subheadline)
                    .foregroundColor(themeColorDark)
                
                Spacer()
                
                // 添加状态显示
                HStack(spacing: 4) {
                    Image(systemName: statusIcon(for: record.status))
                        .foregroundColor(statusColor(for: record.status))
                        .font(.caption)
                    
                    Text(statusText(for: record.status))
                        .font(.caption)
                        .foregroundColor(statusColor(for: record.status))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(for: record.status).opacity(0.1))
                .cornerRadius(12)
            }
            
            if !record.images.isEmpty {
                // 以网格形式显示图片
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 8)
                ], spacing: 8) {
                    ForEach(record.images.prefix(5), id: \.self) { imageURL in
                        Button(action: {
                            print("点击查看图片: \(imageURL)")
                            selectedImageURL = imageURL
                            showingFullScreenImage = true
                        }) {
                            AsyncImage(url: URL(string: APIService.imageURL(for: imageURL))) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                case .failure:
                                    VStack {
                                        Image(systemName: "exclamationmark.triangle")
                                        Text("加载失败")
                                            .font(.caption2)
                                    }
                                    .frame(width: 80, height: 80)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
                .fullScreenCover(item: $selectedImageURL) { imageURL in
                    TaskHelpers.FullScreenImageViewWrapper(imageURL: imageURL, isPresented: $showingFullScreenImage)
                }
            }
            
            // 显示拒绝原因（如果存在）
            if let rejectionReason = record.rejectionReason, !rejectionReason.isEmpty, record.status == .rejected {
                VStack(alignment: .leading, spacing: 4) {
                    Text("拒绝原因:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(rejectionReason)
                        .font(.caption)
                        .foregroundColor(.black)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(10)
    }
    
    private func formatDate(_ dateString: String) -> String {
        if let date = ISO8601DateFormatter().date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
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
            return "待审核"
        case .approved:
            return "已通过"
        case .rejected:
            return "已拒绝"
        case .pending:
            return "未打卡"
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

struct TaskImageView: View {
    let imageUrl: String
    
    var body: some View {
        // 使用APIService生成完整的图片URL
        let fullImageUrl = APIService.imageURL(for: imageUrl)
        
        // 打印URL以便调试
        let _ = print("缩略图URL: \(fullImageUrl)")
        
        if let url = URL(string: fullImageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeColorDark))
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                case .failure(let error):
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                        Text("加载失败")
                            .font(.caption2)
                    }
                    .frame(width: 100, height: 100)
                @unknown default:
                    EmptyView()
                        .frame(width: 100, height: 100)
                }
            }
        } else {
            VStack {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                Text("无效URL")
                    .font(.caption2)
            }
            .frame(width: 100, height: 100)
        }
    }
}

// 为了保持兼容性，添加ImagesGridView的实现，但内部使用TaskImagesGridView
struct ImagesGridView: View {
    let images: [String]
    
    var body: some View {
        TaskImagesGridView(images: images)
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskDetailView(
                task: TapirTask(
                    id: "1",
                    title: "测试任务",
                    description: "这是一个测试任务的描述",
                    dueDate: "2023-01-01T00:00:00.000Z",
                    createdAt: "2023-01-01T00:00:00.000Z",
                    updatedAt: "2023-01-01T00:00:00.000Z",
                    completedToday: false,
                    requiredImages: 2,
                    spaceId: "_",  // 使用下划线替代未使用的变量
                    submitterId: "user1",
                    status: TaskStatus.pending
                ),
                viewModel: TaskViewModel()
            )
        }
    }
}
