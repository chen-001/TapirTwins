import SwiftUI
import Combine
import UIKit

struct SpaceTaskDetailView: View {
    let task: Task
    @StateObject private var viewModel = SpaceViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingSubmitTask = false
    @State private var showingApproveTask = false
    @State private var showingRejectTask = false
    @State private var rejectReason = ""
    @State private var selectedRecord: TaskRecord?
    @State private var isApprover = false
    @State private var isAssignedSubmitter = false
    @State private var canSubmit = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var historyRecords: [HistoryRecord] = []
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            mainContentView
        }
        .navigationBarTitle("任务详情", displayMode: .inline)
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showingSubmitTask) {
            SubmitTaskView(task: task, viewModel: viewModel)
        }
        .sheet(isPresented: $showingApproveTask) {
            ApproveTaskView(
                task: task,
                viewModel: viewModel,
                selectedRecord: $selectedRecord
            )
        }
        .sheet(isPresented: $showingRejectTask) {
            RejectTaskView(
                task: task,
                viewModel: viewModel,
                rejectReason: $rejectReason,
                selectedRecord: $selectedRecord
            )
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("错误"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            handleErrorChange(newValue)
        }
        .onReceive(viewModel.$spaces) { _ in
            handleSpacesChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TaskApproved"))) { _ in
            // 当收到任务审批通过的通知时，刷新数据
            if let spaceId = task.spaceId {
                viewModel.fetchTaskRecords(spaceId: spaceId, taskId: task.id)
                // 这里可以添加获取历史记录的方法
                fetchHistoryRecords(spaceId: spaceId, taskId: task.id)
            }
        }
    }
    
    // 主要内容视图
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 任务详情
            TaskDetailCard(task: task)
            
            // 任务记录列表
            taskRecordsList
            
            // 历史记录列表
            if !historyRecords.isEmpty {
                historyRecordsList
            }
            
            // 底部按钮
            bottomButtonsView
        }
        .padding(.vertical)
    }
    
    // 任务记录列表
    private var taskRecordsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.taskRecords.isEmpty {
                Text("暂无任务记录")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                taskRecordsScrollView
            }
        }
    }
    
    // 历史记录列表
    private var historyRecordsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("打卡历史")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.taskHistoryRecords, id: \.id) { record in
                        HistoryRecordCard(record: record)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 150)
        }
    }
    
    // 任务记录滚动视图
    private var taskRecordsScrollView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.taskRecords) { record in
                    TaskRecordCard(record: record)
                        .onTapGesture {
                            selectedRecord = record
                        }
                        .background(getRecordBackgroundColor(record: record))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 底部按钮视图
    private var bottomButtonsView: some View {
        HStack {
            Spacer()
            
            // 根据任务状态和用户角色显示不同的按钮
            if task.status == .pending && canSubmit {
                submitTaskButton
            } else if task.status == .submitted && isApprover && selectedRecord != nil {
                approveRejectButtonsRow
            }
            
            Spacer()
        }
        .padding()
    }
    
    // 提交任务按钮
    private var submitTaskButton: some View {
        Button(action: {
            showingSubmitTask = true
        }) {
            Text("提交任务")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    // 批准/拒绝按钮行
    private var approveRejectButtonsRow: some View {
        HStack {
            Button(action: {
                showingApproveTask = true
            }) {
                Text("批准")
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
            }
            
            Button(action: {
                showingRejectTask = true
            }) {
                Text("拒绝")
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
            }
        }
    }
    
    // 加载数据
    private func loadData() {
        if let spaceId = task.spaceId {
            print("任务详情页面出现，开始获取任务记录和空间列表")
            viewModel.fetchTaskRecords(spaceId: spaceId, taskId: task.id)
            viewModel.fetchSpaces()
            checkUserRole()
            
            // 获取历史记录
            fetchHistoryRecords(spaceId: spaceId, taskId: task.id)
        }
    }
    
    // 获取历史记录
    private func fetchHistoryRecords(spaceId: String, taskId: String) {
        // 调用ViewModel的方法获取历史记录
        viewModel.fetchTaskHistory(spaceId: spaceId, taskId: taskId) { success, errorMsg in
            if !success, let errorMsg = errorMsg {
                self.errorMessage = "获取历史记录失败: \(errorMsg)"
                self.showError = true
            }
        }
    }
    
    // 处理错误消息变化
    private func handleErrorChange(_ newValue: String) {
        if !newValue.isEmpty {
            errorMessage = newValue
            showError = true
        }
    }
    
    // 处理空间列表变化
    private func handleSpacesChange() {
        print("空间列表已更新，重新检查用户角色")
        checkUserRole()
    }
    
    // 获取记录背景颜色
    private func getRecordBackgroundColor(record: TaskRecord) -> Color {
        if let selectedId = selectedRecord?.id, selectedId == record.id {
            return Color.blue.opacity(0.1)
        }
        return Color.clear
    }
    
    // 检查用户角色
    func checkUserRole() {
        guard let userId = authViewModel.currentUser?.id else { 
            print("检查用户角色失败：当前用户ID为空")
            return 
        }
        
        print("开始检查用户角色，用户ID: \(userId)")
        
        // 检查是否是审批者
        isApprover = false // 默认不是审批者
        
        // 步骤1：检查是否在指定的审批者列表中
        if let approverIds = task.assignedApproverIds {
            isApprover = approverIds.contains(userId)
            print("任务指定的审批者IDs: \(approverIds)，当前用户是否为指定审批者: \(isApprover)")
        } else {
            print("任务没有指定审批者")
        }
        
        // 步骤2：如果是指定的审批者，则直接设置为审批者，不需要检查空间中的角色
        if isApprover {
            return
        }
        
        // 步骤3：如果不是指定的审批者，检查用户在空间中的角色
        checkSpaceMemberRole(userId: userId)
        
        // 检查是否是指定的提交者
        isAssignedSubmitter = task.assignedSubmitterId == userId
        print("任务指定的提交者ID: \(task.assignedSubmitterId ?? "无")，当前用户是否为指定提交者: \(isAssignedSubmitter)")
        
        // 检查是否可以提交任务
        canSubmit = isAssignedSubmitter || task.assignedSubmitterId == nil
        
        print("用户角色检查 - 是审阅者: \(isApprover), 是指定打卡者: \(isAssignedSubmitter), 可以提交: \(canSubmit)")
    }
    
    // 将空间成员角色检查分离为单独的函数
    private func checkSpaceMemberRole(userId: String) {
        guard let spaceId = task.spaceId else { return }
        
        print("检查用户在空间中的角色，空间ID: \(spaceId)")
        
        // 查找当前空间
        let currentSpace = viewModel.spaces.first(where: { $0.id == spaceId })
        guard let space = currentSpace else {
            print("未找到空间，可能空间列表未加载，当前空间数量: \(viewModel.spaces.count)")
            return
        }
        
        print("找到空间: \(space.name)")
        
        // 查找用户在空间中的成员信息
        let member = space.members.first(where: { $0.userId == userId })
        guard let memberInfo = member else {
            print("在空间成员中未找到当前用户")
            return
        }
        
        print("找到用户在空间中的成员信息，角色: \(memberInfo.role.rawValue)")
        
        // 检查用户角色是否为审批者或管理员
        let isApproverRole = memberInfo.role == .approver
        let isAdminRole = memberInfo.role == .admin
        
        isApprover = isApproverRole || isAdminRole
    }
}

// 历史记录卡片
struct HistoryRecordCard: View {
    let record: HistoryRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.description)
                    .font(.subheadline)
                
                Text("操作人: \(record.userName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("时间: \(formatDate(record.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 根据操作类型显示不同的图标
            Image(systemName: getActionIcon(record.action))
                .foregroundColor(getActionColor(record.action))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // 格式化日期
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // 根据操作类型获取图标
    private func getActionIcon(_ action: String) -> String {
        switch action {
        case "approve":
            return "checkmark.circle.fill"
        case "reject":
            return "xmark.circle.fill"
        case "submit":
            return "paperplane.fill"
        default:
            return "doc.text"
        }
    }
    
    // 根据操作类型获取颜色
    private func getActionColor(_ action: String) -> Color {
        switch action {
        case "approve":
            return .green
        case "reject":
            return .red
        case "submit":
            return .blue
        default:
            return .gray
        }
    }
}