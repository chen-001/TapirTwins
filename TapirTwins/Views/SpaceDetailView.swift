import SwiftUI

struct SpaceDetailView: View {
    let spaceId: String
    @ObservedObject private var viewModel = SpaceViewModel()
    @State private var selectedTab = 0
    @State private var showingInviteMember = false
    @State private var showingCreateDream = false
    @State private var showingCreateTask = false
    @State private var showingInviteSheet = false
    @State private var showingInviteCode = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                if let space = viewModel.currentSpace {
                    // 空间信息
                    VStack(alignment: .leading, spacing: 10) {
                        Text(space.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(space.description)
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("创建于: \(formattedDate(space.createdAt))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if isAdmin(space) {
                                Button(action: {
                                    showingInviteCode = true
                                }) {
                                    Label("邀请码", systemImage: "qrcode")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // 选项卡
                    Picker("", selection: $selectedTab) {
                        Text("梦境").tag(0)
                        Text("任务").tag(1)
                        Text("成员").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .onChange(of: selectedTab) { oldValue, newValue in
                        print("标签变更: \(oldValue) -> \(newValue)")
                        if newValue == 0 {
                            viewModel.fetchSpaceDreams(spaceId: spaceId)
                        } else if newValue == 1 {
                            viewModel.fetchSpaceTasks(spaceId: spaceId)
                        } else if newValue == 2 {
                            viewModel.fetchSpaceMembers(spaceId: spaceId)
                        }
                    }
                    
                    // 选项卡内容
                    TabView(selection: $selectedTab) {
                        // 梦境选项卡
                        SpaceDreamsTab(viewModel: viewModel, spaceId: spaceId, showingCreateDream: $showingCreateDream)
                            .tag(0)
                        
                        // 任务选项卡
                        SpaceTasksTab(viewModel: viewModel, spaceId: spaceId, showingCreateTask: $showingCreateTask)
                            .tag(1)
                        
                        // 成员选项卡
                        SpaceMembersTab(viewModel: viewModel, space: space, showingInviteMember: $showingInviteMember)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                } else {
                    Text("加载中...")
                        .foregroundColor(.gray)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .navigationTitle("空间详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInviteMember) {
            InviteMemberView(isPresented: $showingInviteMember, viewModel: viewModel, spaceId: spaceId)
        }
        .sheet(isPresented: $showingCreateDream) {
            CreateSpaceDreamView(isPresented: $showingCreateDream, viewModel: viewModel, spaceId: spaceId)
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateSpaceTaskView(isPresented: $showingCreateTask, viewModel: viewModel, spaceId: spaceId)
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteMemberView(isPresented: $showingInviteSheet, viewModel: viewModel, spaceId: spaceId)
        }
        .alert("错误", isPresented: $showError, actions: {
            Button("确定") {}
        }, message: {
            Text(viewModel.errorMessage)
        })
        .alert(isPresented: $showingInviteCode) {
            if let inviteCode = viewModel.currentSpace?.inviteCode {
                return Alert(
                    title: Text("空间邀请码"),
                    message: Text(inviteCode),
                    primaryButton: .default(Text("复制")) {
                        UIPasteboard.general.string = inviteCode
                    },
                    secondaryButton: .cancel(Text("关闭"))
                )
            } else {
                return Alert(
                    title: Text("错误"),
                    message: Text("无法获取邀请码"),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
        .onAppear {
            print("空间详情视图出现")
            viewModel.fetchSpace(id: spaceId)
            viewModel.fetchSpaceDreams(spaceId: spaceId)
            viewModel.fetchSpaceTasks(spaceId: spaceId)
        }
        .onChange(of: viewModel.showError) { oldValue, newValue in
            showError = newValue
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    private func roleText(_ role: MemberRole) -> String {
        switch role {
        case .admin:
            return "管理员"
        case .approver:
            return "审批者"
        case .submitter:
            return "打卡者"
        }
    }
    
    private func roleColor(_ role: MemberRole) -> Color {
        switch role {
        case .admin:
            return .red
        case .approver:
            return .blue
        case .submitter:
            return .green
        }
    }
    
    private func isAdmin(_ space: Space) -> Bool {
        guard let currentUser = AuthService.shared.getCurrentUser() else {
            return false
        }
        
        return space.members.first(where: { $0.userId == currentUser.id })?.role == .admin
    }
}

// 梦境选项卡
struct SpaceDreamsTab: View {
    @ObservedObject var viewModel: SpaceViewModel
    let spaceId: String
    @Binding var showingCreateDream: Bool
    
    var body: some View {
        VStack {
            if viewModel.spaceDreams.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("还没有梦境记录")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showingCreateDream = true
                    }) {
                        Text("记录梦境")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.spaceDreams, id: \.id) { dream in
                        NavigationLink(destination: SpaceDreamDetailView(dream: dream)) {
                            SpaceDreamRow(dream: dream)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                Button(action: {
                    showingCreateDream = true
                }) {
                    Text("记录梦境")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
}

// 任务选项卡
struct SpaceTasksTab: View {
    @ObservedObject var viewModel: SpaceViewModel
    let spaceId: String
    @Binding var showingCreateTask: Bool
    @State private var isRefreshing = false
    @State private var showApprovalSection = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var retryCount = 0
    @State private var showTaskRecordsError = false
    @State private var taskRecordsErrorMessage = ""
    
    var body: some View {
        VStack {
            // 检查当前用户是否是审阅者
            if isUserApprover() {
                VStack {
                    HStack {
                        Text("审核任务")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showApprovalSection.toggle()
                        }) {
                            Image(systemName: showApprovalSection ? "chevron.up" : "chevron.down")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if showApprovalSection {
                        if showTaskRecordsError {
                            VStack {
                                Text(taskRecordsErrorMessage)
                                    .foregroundColor(.red)
                                    .padding()
                                
                                Button(action: {
                                    refreshTaskRecords()
                                }) {
                                    Text("重试获取审核任务")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                .padding(.bottom)
                            }
                        } else {
                            TaskApprovalView(tasks: viewModel.spaceTasks, viewModel: viewModel)
                                .padding(.bottom)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            // 显示错误信息（如果有）
            if viewModel.showError {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .padding()
                
                Button(action: {
                    refreshTasks()
                }) {
                    Text("重试")
                        .foregroundColor(.blue)
                }
                .padding(.bottom)
            }
            
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .padding()
            } else if viewModel.spaceTasks.isEmpty {
                VStack {
                    Text("暂无任务")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button(action: {
                        showingCreateTask = true
                    }) {
                        Text("创建第一个任务")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            } else {
                // 添加下拉刷新功能
                List {
                    ForEach(viewModel.spaceTasks, id: \.id) { task in
                        NavigationLink(destination: SpaceTaskDetailView(task: task)) {
                            SpaceTaskRow(task: task)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    await refreshTasksAsync()
                }
                
                HStack {
                    Button(action: {
                        showingCreateTask = true
                    }) {
                        Text("创建任务")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        refreshTasks()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 50)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            
            if isRefreshing {
                ProgressView("刷新中...")
                    .padding()
            }
        }
        .onAppear {
            print("任务选项卡出现，刷新任务列表...")
            refreshTasks()
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("错误"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    private func refreshTasks() {
        isRefreshing = true
        
        // 记录重试次数
        retryCount += 1
        print("刷新任务列表，尝试次数: \(retryCount)")
        
        viewModel.fetchSpaceTasks(spaceId: spaceId)
        
        // 同时获取任务记录
        if isUserApprover() {
            refreshTaskRecords()
        }
        
        // 延迟关闭刷新状态，给用户更好的反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
            
            // 检查是否有错误
            if viewModel.showError {
                errorMessage = viewModel.errorMessage
                showErrorAlert = true
                
                // 如果重试次数小于3，自动重试
                if retryCount < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        refreshTasks()
                    }
                }
            } else {
                // 成功后重置重试计数
                retryCount = 0
            }
        }
    }
    
    private func refreshTaskRecords() {
        // 重置错误状态
        showTaskRecordsError = false
        taskRecordsErrorMessage = ""
        
        // 获取任务记录
        viewModel.fetchTaskRecords(spaceId: spaceId) { success, error in
            if !success, let errorMsg = error {
                DispatchQueue.main.async {
                    showTaskRecordsError = true
                    taskRecordsErrorMessage = "获取任务记录失败: \(errorMsg)"
                    print("获取任务记录失败: \(errorMsg)")
                    
                    // 如果重试次数小于3，自动重试
                    if retryCount < 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            refreshTaskRecords()
                        }
                    }
                }
            } else {
                // 成功获取任务记录
                print("成功获取任务记录")
            }
        }
    }
    
    private func refreshTasksAsync() async {
        isRefreshing = true
        retryCount += 1
        
        // 模拟异步操作
        await withCheckedContinuation { continuation in
            viewModel.fetchSpaceTasks(spaceId: spaceId)
            
            // 同时获取任务记录
            if isUserApprover() {
                refreshTaskRecords()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isRefreshing = false
                
                // 检查是否有错误
                if viewModel.showError {
                    errorMessage = viewModel.errorMessage
                    showErrorAlert = true
                } else {
                    // 成功后重置重试计数
                    retryCount = 0
                }
                
                continuation.resume()
            }
        }
    }
    
    // 检查当前用户是否是审阅者
    private func isUserApprover() -> Bool {
        guard let currentUser = AuthService.shared.getCurrentUser() else { return false }
        let userId = currentUser.id
        
        if let space = viewModel.currentSpace {
            if let member = space.members.first(where: { $0.userId == userId }) {
                return member.role == .approver || member.role == .admin
            }
        }
        
        return false
    }
}

// 成员选项卡
struct SpaceMembersTab: View {
    @ObservedObject var viewModel: SpaceViewModel
    let space: Space
    @Binding var showingInviteMember: Bool
    
    var body: some View {
        VStack {
            List {
                ForEach(space.members, id: \.userId) { member in
                    MemberRow(member: member)
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            Button(action: {
                showingInviteMember = true
            }) {
                Text("邀请成员")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
            }
        }
    }
}

// 梦境行
struct SpaceDreamRow: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dream.title)
                .font(.headline)
            
            Text(dream.content)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                if let username = dream.username {
                    Text("记录者: \(username)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("日期: \(formattedDate(dream.date))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
}

// 任务行
struct SpaceTaskRow: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.headline)
            
            Text(task.description ?? "无描述")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            // 显示指定的打卡者和审阅者
            if task.assignedSubmitterName != nil || (task.assignedApproverNames != nil && !task.assignedApproverNames!.isEmpty) {
                VStack(alignment: .leading, spacing: 4) {
                    if let submitterName = task.assignedSubmitterName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("打卡者: \(submitterName)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let approverNames = task.assignedApproverNames, !approverNames.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("审阅者: \(approverNames.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.green)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            
            HStack {
                if let status = task.status {
                    Text("状态: \(statusText(status))")
                        .font(.caption)
                        .foregroundColor(statusColor(status))
                } else {
                    Text("状态: 待完成")
                        .font(.caption)
                        .foregroundColor(Color.gray)
                }
                
                Spacer()
                
                Text("截止日期: \(task.dueDate != nil ? formattedDate(task.dueDate!) : "无")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func statusText(_ status: TaskStatus) -> String {
        switch status {
        case .pending:
            return "待完成"
        case .submitted:
            return "待审批"
        case .approved:
            return "已完成"
        case .rejected:
            return "已拒绝"
        }
    }
    
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .pending:
            return Color.orange
        case .submitted:
            return Color.blue
        case .approved:
            return Color.green
        case .rejected:
            return Color.red
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy-MM-dd"
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
}

// 成员行
struct MemberRow: View {
    let member: SpaceMember
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.username)
                    .font(.headline)
                
                Text(roleText(member.role))
                    .font(.caption)
                    .foregroundColor(roleColor(member.role))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func roleText(_ role: MemberRole) -> String {
        switch role {
        case .submitter:
            return "提交者"
        case .approver:
            return "审批者"
        case .admin:
            return "管理员"
        }
    }
    
    private func roleColor(_ role: MemberRole) -> Color {
        switch role {
        case .submitter:
            return .blue
        case .approver:
            return .green
        case .admin:
            return .purple
        }
    }
}

// 创建空间梦境视图
struct CreateSpaceDreamView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SpaceViewModel
    let spaceId: String
    @State private var title = ""
    @State private var content = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("梦境信息")) {
                    TextField("标题", text: $title)
                    
                    TextEditor(text: $content)
                        .frame(height: 200)
                    
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("记录梦境")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    viewModel.createSpaceDream(spaceId: spaceId, title: title, content: content, date: date)
                    isPresented = false
                }
                .disabled(title.isEmpty || content.isEmpty)
            )
        }
    }
}

// 创建空间任务视图
struct CreateSpaceTaskView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SpaceViewModel
    let spaceId: String
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var requiredImages = 1
    @State private var isSubmitting = false
    @State private var selectedSubmitterId: String? = nil
    @State private var selectedApproverIds: [String] = []
    @State private var showingSubmitterPicker = false
    @State private var showingApproverPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("标题", text: $title)
                    
                    TextEditor(text: $description)
                        .frame(height: 150)
                    
                    DatePicker("截止日期", selection: $dueDate, displayedComponents: .date)
                    
                    Stepper("需要图片数量: \(requiredImages)", value: $requiredImages, in: 1...5)
                }
                
                Section(header: Text("指派信息")) {
                    // 选择打卡者
                    Button(action: {
                        showingSubmitterPicker = true
                    }) {
                        HStack {
                            Text("指定打卡者")
                            Spacer()
                            if let submitterId = selectedSubmitterId,
                               let space = viewModel.currentSpace,
                               let member = space.members.first(where: { $0.userId == submitterId }) {
                                Text(member.username)
                                    .foregroundColor(.primary)
                            } else {
                                Text("任何成员")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 选择审阅者
                    Button(action: {
                        showingApproverPicker = true
                    }) {
                        HStack {
                            Text("指定审阅者")
                            Spacer()
                            if !selectedApproverIds.isEmpty,
                               let space = viewModel.currentSpace {
                                let names = selectedApproverIds.compactMap { id in
                                    space.members.first(where: { $0.userId == id })?.username
                                }.joined(separator: ", ")
                                Text(names)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            } else {
                                Text("任何审批者")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("创建任务")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    // 防止重复提交
                    guard !isSubmitting else { return }
                    isSubmitting = true
                    
                    viewModel.createSpaceTask(
                        spaceId: spaceId, 
                        title: title, 
                        description: description, 
                        dueDate: dueDate, 
                        requiredImages: requiredImages,
                        assignedSubmitterId: selectedSubmitterId,
                        assignedApproverIds: selectedApproverIds.isEmpty ? nil : selectedApproverIds
                    )
                    
                    // 延迟关闭表单，确保网络请求有时间完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isSubmitting = false
                        isPresented = false
                    }
                }
                .disabled(title.isEmpty || description.isEmpty || isSubmitting)
            )
            .overlay(
                Group {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            )
            .sheet(isPresented: $showingSubmitterPicker) {
                SubmitterPickerView(
                    space: viewModel.currentSpace,
                    selectedSubmitterId: $selectedSubmitterId,
                    isPresented: $showingSubmitterPicker
                )
            }
            .sheet(isPresented: $showingApproverPicker) {
                ApproverPickerView(
                    space: viewModel.currentSpace,
                    selectedApproverIds: $selectedApproverIds,
                    isPresented: $showingApproverPicker
                )
            }
            .onAppear {
                // 确保有空间数据
                if viewModel.currentSpace == nil {
                    viewModel.fetchSpace(id: spaceId)
                }
            }
        }
    }
}

// 打卡者选择视图
struct SubmitterPickerView: View {
    let space: Space?
    @Binding var selectedSubmitterId: String?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                // 添加"任何成员"选项
                Button(action: {
                    selectedSubmitterId = nil
                    isPresented = false
                }) {
                    HStack {
                        Text("任何成员")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedSubmitterId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // 显示所有成员
                if let space = space {
                    ForEach(space.members.filter { $0.role == .submitter || $0.role == .admin }) { member in
                        Button(action: {
                            selectedSubmitterId = member.userId
                            isPresented = false
                        }) {
                            HStack {
                                Text(member.username)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedSubmitterId == member.userId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择打卡者")
            .navigationBarItems(trailing: Button("取消") {
                isPresented = false
            })
        }
    }
}

// 审阅者选择视图
struct ApproverPickerView: View {
    let space: Space?
    @Binding var selectedApproverIds: [String]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                // 添加"任何审批者"选项
                Button(action: {
                    selectedApproverIds = []
                    isPresented = false
                }) {
                    HStack {
                        Text("任何审批者")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedApproverIds.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // 显示所有成员
                if let space = space {
                    ForEach(space.members) { member in
                        Button(action: {
                            if selectedApproverIds.contains(member.userId) {
                                selectedApproverIds.removeAll { $0 == member.userId }
                            } else {
                                selectedApproverIds.append(member.userId)
                            }
                        }) {
                            HStack {
                                Text(member.username)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedApproverIds.contains(member.userId) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择审阅者")
            .navigationBarItems(
                trailing: Button("完成") {
                    isPresented = false
                }
            )
        }
    }
}

struct SpaceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SpaceDetailView(spaceId: "1")
    }
}