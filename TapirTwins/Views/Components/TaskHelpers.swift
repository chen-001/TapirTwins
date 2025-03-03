import SwiftUI
import UIKit

// 这个文件暂时保留为空，因为所需的组件已经在SpaceTaskDetailView.swift中定义
// 后续可以将SpaceTaskDetailView.swift中的辅助函数和组件移动到这里，以实现代码复用 

// 状态文本函数
func statusText(_ status: TaskStatus) -> String {
    switch status {
    case .pending:
        return "待提交"
    case .submitted:
        return "已提交"
    case .approved:
        return "已批准"
    case .rejected:
        return "已拒绝"
    }
}

// 状态颜色函数
func statusColor(_ status: TaskStatus) -> Color {
    switch status {
    case .pending:
        return .gray
    case .submitted:
        return .blue
    case .approved:
        return .green
    case .rejected:
        return .red
    }
}

// 日期格式化函数
func formattedDate(_ dateString: String?) -> String {
    guard let dateString = dateString else { return "无截止日期" }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    
    if let date = dateFormatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }
    
    return dateString
}

// 任务记录行组件
struct TaskRecordRow: View {
    let record: TaskRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("提交时间: \(formattedDate(record.createdAt))")
                    .font(.subheadline)
                
                Spacer()
                
                Text(statusText(record.status))
                    .font(.subheadline)
                    .foregroundColor(statusColor(record.status))
            }
            
            if let submitterName = record.submitterName {
                Text("提交者: \(submitterName)")
                    .font(.subheadline)
            }
            
            if record.status == .approved, let approverName = record.approverName {
                Text("审批者: \(approverName)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            if record.status == .rejected, let reason = record.rejectionReason {
                Text("拒绝原因: \(reason)")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            
            if !record.images.isEmpty {
                Text("包含 \(record.images.count) 张图片")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxImages: Int
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                if parent.selectedImages.count < parent.maxImages {
                    parent.selectedImages.append(image)
                }
            }
            picker.dismiss(animated: true)
        }
    }
}

// 提交任务视图
struct SubmitTaskView: View {
    let task: TapirTask
    @ObservedObject var viewModel: SpaceViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImages: [UIImage] = []
    @State private var isShowingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("提交任务")
                    .font(.title)
                    .padding()
                
                Text("请上传 \(task.requiredImages) 张图片")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        if selectedImages.count < task.requiredImages {
                            Button(action: {
                                isShowingImagePicker = true
                            }) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 30))
                                    Text("添加图片")
                                        .font(.caption)
                                }
                                .frame(width: 100, height: 100)
                                .background(Color(UIColor.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: {
                    if let spaceId = task.spaceId {
                        viewModel.submitTask(spaceId: spaceId, taskId: task.id, images: selectedImages)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("提交")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedImages.count >= task.requiredImages ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(selectedImages.count < task.requiredImages)
                .padding()
            }
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImages: $selectedImages, maxImages: task.requiredImages)
            }
        }
    }
}

// 拒绝任务视图
struct RejectTaskView: View {
    let task: TapirTask
    @ObservedObject var viewModel: SpaceViewModel
    @Binding var rejectReason: String
    @Binding var selectedRecord: TaskRecord?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("拒绝任务")
                    .font(.title)
                    .padding()
                
                if let record = selectedRecord {
                    Text("任务记录ID: \(record.id)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                }
                
                Text("请输入拒绝原因")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                TextEditor(text: $rejectReason)
                    .padding()
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding()
                
                Spacer()
                
                Button(action: {
                    if let record = selectedRecord, let spaceId = task.spaceId {
                        viewModel.rejectTaskRecord(spaceId: spaceId, recordId: record.id, reason: rejectReason)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("提交")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(!rejectReason.isEmpty ? Color.red : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(rejectReason.isEmpty)
                .padding()
            }
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 审批任务视图
struct ApproveTaskView: View {
    let task: TapirTask
    @ObservedObject var viewModel: SpaceViewModel
    @State private var approveComment: String = ""
    @Binding var selectedRecord: TaskRecord?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("批准任务")
                    .font(.title)
                    .padding()
                
                if let record = selectedRecord {
                    Text("任务记录ID: \(record.id)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                }
                
                Text("请输入审批词")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                TextEditor(text: $approveComment)
                    .padding()
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding()
                
                Spacer()
                
                Button(action: {
                    if let record = selectedRecord, let spaceId = task.spaceId {
                        viewModel.approveTaskRecord(spaceId: spaceId, recordId: record.id, comment: approveComment)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("提交")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

// 任务审核视图
struct TaskApprovalView: View {
    let tasks: [TapirTask]
    @ObservedObject var viewModel: SpaceViewModel
    @State private var selectedTask: TapirTask? = nil
    @State private var selectedRecord: TaskRecord? = nil
    @State private var showingApproveAlert = false
    @State private var showingRejectSheet = false
    @State private var rejectReason = ""
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("待审核任务")
                .font(.headline)
                .padding(.horizontal)
            
            if tasks.filter({ $0.status == .submitted }).isEmpty {
                Text("暂无待审核任务")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tasks.filter { $0.status == .submitted }) { task in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(task.title)
                                    .font(.headline)
                                
                                if let description = task.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                                
                                // 查找该任务的最新提交记录
                                let records = viewModel.taskRecords.filter { $0.taskId == task.id && $0.status == .submitted }
                                
                                if records.isEmpty {
                                    Text("无法找到提交记录")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.vertical, 4)
                                } else if let latestRecord = records.first {
                                    HStack {
                                        Text("提交者: \(latestRecord.submitterName ?? "未知")")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        Text("提交时间: \(formattedDate(latestRecord.createdAt))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack {
                                        Button(action: {
                                            selectedTask = task
                                            selectedRecord = latestRecord
                                            showingApproveAlert = true
                                        }) {
                                            Text("通过")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.green)
                                                .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            selectedTask = task
                                            selectedRecord = latestRecord
                                            showingRejectSheet = true
                                        }) {
                                            Text("拒绝")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.red)
                                                .cornerRadius(8)
                                        }
                                        
                                        Spacer()
                                        
                                        NavigationLink(destination: SpaceTaskDetailView(task: task)) {
                                            Text("详情")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.blue)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .alert(isPresented: $showingApproveAlert) {
            Alert(
                title: Text("审核通过"),
                message: Text("确定要通过这个任务吗？"),
                primaryButton: .default(Text("确定")) {
                    if let task = selectedTask, let record = selectedRecord, let spaceId = task.spaceId {
                        viewModel.approveTaskRecord(spaceId: spaceId, recordId: record.id)
                    } else {
                        errorMessage = "无法审核任务：缺少必要信息"
                        showError = true
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .sheet(isPresented: $showingRejectSheet) {
            if let task = selectedTask, let selectedRecord = selectedRecord {
                RejectTaskView(
                    task: task,
                    viewModel: viewModel,
                    rejectReason: $rejectReason,
                    selectedRecord: $selectedRecord
                )
            } else {
                Text("无法加载拒绝任务视图：缺少必要信息")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// 任务详情卡片组件
struct TaskDetailCard: View {
    let task: TapirTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 任务标题
            Text(task.title)
                .font(.title)
                .fontWeight(.bold)
            
            // 任务描述
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.body)
            }
            
            // 任务状态
            HStack {
                Text("状态:")
                    .font(.headline)
                
                Text(statusText(task.status ?? .pending))
                    .foregroundColor(statusColor(task.status ?? .pending))
                    .fontWeight(.semibold)
            }
            
            // 截止日期
            if let dueDate = task.dueDate {
                HStack {
                    Text("截止日期:")
                        .font(.headline)
                    
                    Text(formattedDate(dueDate))
                        .fontWeight(.semibold)
                }
            }
            
            // 指定打卡者
            if let submitterName = task.assignedSubmitterName {
                HStack {
                    Text("指定打卡者:")
                        .font(.headline)
                    
                    Text(submitterName)
                        .fontWeight(.semibold)
                }
            }
            
            // 审批者
            if let approverNames = task.assignedApproverNames, !approverNames.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("审批者:")
                        .font(.headline)
                    
                    ForEach(approverNames, id: \.self) { name in
                        Text("• \(name)")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // 格式化日期
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // 获取状态文本
    private func statusText(_ status: TaskStatus) -> String {
        switch status {
        case .pending:
            return "待提交"
        case .submitted:
            return "已提交"
        case .approved:
            return "已批准"
        case .rejected:
            return "已拒绝"
        }
    }
    
    // 获取状态颜色
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .pending:
            return .gray
        case .submitted:
            return .blue
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

// 任务记录卡片组件
struct TaskRecordCard: View {
    let record: TaskRecord
    @State private var selectedImageURL: String? = nil
    @State private var showingFullScreenImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("提交时间:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedDate(record.createdAt))
                    .font(.subheadline)
            }
            
            HStack {
                Text("状态:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(statusText(record.status))
                    .font(.subheadline)
                    .foregroundColor(statusColor(record.status))
                    .fontWeight(.semibold)
            }
            
            if let submitterName = record.submitterName {
                HStack {
                    Text("提交者:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(submitterName)
                        .font(.subheadline)
                }
            }
            
            if let approverName = record.approverName {
                HStack {
                    Text("审批者:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(approverName)
                        .font(.subheadline)
                }
            }
            
            if let rejectReason = record.rejectionReason, !rejectReason.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("拒绝原因:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(rejectReason)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            // 显示图片
            if !record.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(record.images, id: \.self) { imageUrl in
                            // 使用APIService生成完整的图片URL
                            let fullImageUrl = APIService.imageURL(for: imageUrl)
                            
                            Button(action: {
                                print("点击查看图片: \(imageUrl)")
                                selectedImageURL = imageUrl  // 存储原始图片ID，而不是完整URL
                                showingFullScreenImage = true
                            }) {
                                AsyncImage(url: URL(string: fullImageUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 80, height: 80)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    case .failure(let error):
                                        VStack(spacing: 4) {
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
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
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .sheet(isPresented: $showingFullScreenImage) {
            if let imageURL = selectedImageURL {
                TaskHelpers.FullScreenImageViewWrapper(imageURL: imageURL, isPresented: $showingFullScreenImage)
            } else {
                Text("无法加载图片")
                    .padding()
            }
        }
    }
    
    // 格式化日期
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // 获取状态文本
    private func statusText(_ status: TaskStatus) -> String {
        switch status {
        case .pending:
            return "待提交"
        case .submitted:
            return "已提交"
        case .approved:
            return "已批准"
        case .rejected:
            return "已拒绝"
        }
    }
    
    // 获取状态颜色
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .pending:
            return .gray
        case .submitted:
            return .blue
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

// TaskHelpers命名空间
enum TaskHelpers {
    // 添加一个包装视图来处理URL转换逻辑
    struct FullScreenImageViewWrapper: View {
        let imageURL: String
        @Binding var isPresented: Bool
        
        var body: some View {
            let urlString = APIService.imageURL(for: imageURL)
            
            VStack {
                if let url = URL(string: urlString) {
                    FullScreenImageView(imageURL: url, isPresented: $isPresented)
                        .onAppear {
                            print("FullScreenImageViewWrapper - 显示图片URL: \(url.absoluteString)")
                        }
                } else {
                    VStack(spacing: 20) {
                        Text("无法创建图片URL")
                            .font(.headline)
                            .padding()
                        
                        Text("原始URL: \(imageURL)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("转换后URL: \(urlString)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        // 尝试使用不同的URL格式
                        if let alternativeURL = createAlternativeURL(from: imageURL) {
                            Button("尝试替代URL") {
                                // 使用替代URL打开图片
                                if let url = URL(string: alternativeURL) {
                                    print("尝试使用替代URL: \(alternativeURL)")
                                    // 关闭当前视图并重新打开
                                    isPresented = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        // 这里应该触发一个通知或使用其他方式来打开新的URL
                                        // 由于SwiftUI的限制，这里只是一个示例
                                        print("应该使用URL打开新视图: \(url.absoluteString)")
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button("关闭") {
                            isPresented = false
                        }
                        .padding()
                    }
                }
            }
        }
        
        // 创建替代URL的方法
        private func createAlternativeURL(from originalURL: String) -> String? {
            // 如果URL包含/api/images/，尝试移除/api部分
            if originalURL.contains("/api/images/") {
                return originalURL.replacingOccurrences(of: "/api/images/", with: "/images/")
            }
            // 如果URL不包含/api/但包含/images/，尝试添加/api
            else if !originalURL.contains("/api/") && originalURL.contains("/images/") {
                let components = originalURL.components(separatedBy: "/images/")
                if components.count > 1 {
                    return "\(components[0])/api/images/\(components[1])"
                }
            }
            // 如果是简单的文件名，尝试直接构建完整URL
            else if !originalURL.contains("/") {
                // 从APIConfig获取基础URL
                let baseURLString = APIConfig.baseURL
                if let url = URL(string: baseURLString), let host = url.host {
                    let scheme = url.scheme ?? "http"
                    let port = url.port != nil ? ":\(url.port!)" : ""
                    let baseHost = "\(scheme)://\(host)\(port)"
                    return "\(baseHost)/images/\(originalURL)"
                }
            }
            
            return nil
        }
    }
}

// 包装视图来处理URL转换逻辑
struct FullScreenImageView: View {
    let imageURL: URL
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showDebugInfo = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    // 调试信息
                    if showDebugInfo {
                        VStack {
                            Text("图片URL: \(imageURL.absoluteString)")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            if let errorMessage = errorMessage {
                                Text("错误: \(errorMessage)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding()
                        .zIndex(2)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2.0)
                            .zIndex(1)
                    }
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1), 5)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if scale > 1 {
                                        scale = 1
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2
                                    }
                                }
                            }
                    } else if !isLoading {
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                            Text("图片加载失败")
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button("重试") {
                                loadImage()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 10)
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    showDebugInfo.toggle()
                }) {
                    Image(systemName: showDebugInfo ? "info.circle.fill" : "info.circle")
                        .foregroundColor(.white)
                },
                trailing: Button(action: {
                    isPresented = false
                }) {
                    Text("关闭")
                        .foregroundColor(.white)
                }
            )
            .background(Color.black)
            .onAppear {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        isLoading = true
        errorMessage = nil
        
        print("开始加载图片: \(imageURL.absoluteString)")
        
        // 创建请求对象以便添加调试信息
        var request = URLRequest(url: imageURL)
        request.addValue("TapirTwins/1.0", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData // 忽略缓存，强制重新加载
        
        // 打印完整的请求信息
        print("请求URL: \(request.url?.absoluteString ?? "nil")")
        print("请求方法: \(request.httpMethod ?? "GET")")
        print("请求头: \(request.allHTTPHeaderFields ?? [:])")
        
        // 尝试使用原始URL加载
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "网络错误: \(error.localizedDescription)"
                    print("图片加载失败: \(error.localizedDescription)")
                    
                    // 尝试使用百分比编码的URL重新加载
                    if let encodedURLString = imageURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let encodedURL = URL(string: encodedURLString) {
                        print("尝试使用编码后的URL重新加载: \(encodedURLString)")
                        retryWithEncodedURL(encodedURL)
                    }
                    return
                }
                
                // 打印完整的响应信息
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP状态码: \(httpResponse.statusCode)")
                    print("响应头: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode != 200 {
                        errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        print("图片加载失败: 服务器返回 \(httpResponse.statusCode)")
                        
                        // 如果是404错误，尝试修改URL路径
                        if httpResponse.statusCode == 404 {
                            let originalURLString = imageURL.absoluteString
                            // 尝试不同的URL格式
                            var alternativeURL: URL?
                            
                            // 尝试1: 如果URL包含/api/images/，尝试移除/api部分
                            if originalURLString.contains("/api/images/") {
                                let newURLString = originalURLString.replacingOccurrences(of: "/api/images/", with: "/images/")
                                alternativeURL = URL(string: newURLString)
                                print("尝试替代URL (移除/api): \(newURLString)")
                            } 
                            // 尝试2: 如果URL不包含/api/但包含/images/，尝试添加/api
                            else if !originalURLString.contains("/api/") && originalURLString.contains("/images/") {
                                let components = originalURLString.components(separatedBy: "/images/")
                                if components.count > 1 {
                                    let newURLString = "\(components[0])/api/images/\(components[1])"
                                    alternativeURL = URL(string: newURLString)
                                    print("尝试替代URL (添加/api): \(newURLString)")
                                }
                            }
                            
                            if let alternativeURL = alternativeURL {
                                print("尝试使用替代URL: \(alternativeURL.absoluteString)")
                                retryWithEncodedURL(alternativeURL)
                                return
                            }
                        }
                        return
                    }
                } else {
                    errorMessage = "无效的响应"
                    print("图片加载失败: 无效的响应")
                    return
                }
                
                guard let data = data else {
                    errorMessage = "无数据返回"
                    print("图片加载失败: 无数据返回")
                    return
                }
                
                print("接收到数据大小: \(data.count) 字节")
                
                // 检查数据的MIME类型
                if let httpResponse = response as? HTTPURLResponse,
                   let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                    print("内容类型: \(contentType)")
                    
                    // 如果不是图片类型，可能是返回了错误页面或其他内容
                    if !contentType.contains("image/") {
                        errorMessage = "返回的不是图片数据 (类型: \(contentType))"
                        print("图片加载失败: 返回的不是图片数据")
                        
                        // 尝试输出前100个字节的数据，帮助诊断
                        if data.count > 0 {
                            let previewSize = min(100, data.count)
                            let dataPreview = data.prefix(previewSize)
                            print("数据预览: \(dataPreview)")
                            
                            if let textContent = String(data: data, encoding: .utf8) {
                                print("文本内容预览: \(String(textContent.prefix(200)))")
                            }
                        }
                        return
                    }
                }
                
                guard let loadedImage = UIImage(data: data) else {
                    errorMessage = "无法解析图片数据"
                    print("图片加载失败: 无法解析图片数据")
                    
                    // 尝试输出前100个字节的数据，帮助诊断
                    if data.count > 0 {
                        let previewSize = min(100, data.count)
                        let dataPreview = data.prefix(previewSize)
                        print("数据预览: \(dataPreview)")
                    }
                    
                    return
                }
                
                self.image = loadedImage
                print("图片加载成功: \(imageURL.absoluteString), 尺寸: \(loadedImage.size.width) x \(loadedImage.size.height)")
            }
        }
        
        task.resume()
    }
    
    private func retryWithEncodedURL(_ url: URL) {
        print("使用编码后的URL重试加载图片: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.addValue("TapirTwins/1.0", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "重试失败: \(error.localizedDescription)"
                    print("编码URL后重试仍然失败: \(error.localizedDescription)")
                    return
                }
                
                // 打印响应信息
                if let httpResponse = response as? HTTPURLResponse {
                    print("重试 HTTP状态码: \(httpResponse.statusCode)")
                    print("重试 响应头: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode != 200 {
                        errorMessage = "重试服务器错误: \(httpResponse.statusCode)"
                        print("重试图片加载失败: 服务器返回 \(httpResponse.statusCode)")
                        return
                    }
                }
                
                guard let data = data else {
                    errorMessage = "重试后无数据返回"
                    print("重试后无数据返回")
                    return
                }
                
                print("重试接收到数据大小: \(data.count) 字节")
                
                guard let loadedImage = UIImage(data: data) else {
                    errorMessage = "重试后无法加载图片数据"
                    print("编码URL后重试仍然无法加载图片数据")
                    
                    // 尝试输出前100个字节的数据，帮助诊断
                    if data.count > 0 {
                        let previewSize = min(100, data.count)
                        let dataPreview = data.prefix(previewSize)
                        print("重试数据预览: \(dataPreview)")
                    }
                    
                    return
                }
                
                self.image = loadedImage
                print("使用编码URL重试成功! 图片尺寸: \(loadedImage.size.width) x \(loadedImage.size.height)")
            }
        }
        
        task.resume()
    }
}

// 图片网格视图
struct TaskImagesGridView: View {
    let images: [String]
    @State private var selectedImage: String? = nil
    @State private var showingFullScreenImage = false
    
    var body: some View {
        if !images.isEmpty {
            VStack(alignment: .leading) {
                Text("附件")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                    ForEach(images, id: \.self) { imageUrl in
                        Button(action: {
                            print("点击查看图片: \(imageUrl)")
                            selectedImage = imageUrl
                            showingFullScreenImage = true
                        }) {
                            ThumbnailImageView(imageUrl: imageUrl)
                                .frame(height: 80)
                                .cornerRadius(8)
                        }
                    }
                }
                .sheet(isPresented: $showingFullScreenImage) {
                    if let imageURL = selectedImage, let url = URL(string: APIService.imageURL(for: imageURL)) {
                        TaskHelpers.FullScreenImageViewWrapper(imageURL: imageURL, isPresented: $showingFullScreenImage)
                    } else {
                        Text("无法加载图片")
                            .padding()
                    }
                }
            }
        }
    }
}

// 缩略图视图
struct ThumbnailImageView: View {
    let imageUrl: String
    
    var body: some View {
        // 使用APIService生成完整的图片URL
        let fullImageUrl = APIService.imageURL(for: imageUrl)
        
        // 打印URL以便调试
        let _ = print("缩略图URL: \(fullImageUrl)")
        
        return AsyncImage(url: URL(string: fullImageUrl)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(let error):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("加载失败")
                        .font(.caption)
                }
                .onAppear {
                    print("缩略图加载失败: \(error.localizedDescription), URL: \(fullImageUrl)")
                }
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - 调试工具

struct ImageServerDebugView: View {
    @State private var serverInfo: String = "加载中..."
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("图片服务器调试")
                    .font(.title)
                    .padding(.bottom)
                
                if isLoading {
                    ProgressView()
                } else {
                    Text(serverInfo)
                        .font(.system(.body, design: .monospaced))
                }
                
                Button("刷新") {
                    checkImageServer()
                }
                .padding(.top)
            }
            .padding()
        }
        .onAppear {
            checkImageServer()
        }
    }
    
    private func checkImageServer() {
        isLoading = true
        serverInfo = "正在检查图片服务器..."
        
        // 检查图片列表API
        let urlString = "\(APIConfig.API.base)/images"
        
        guard let url = URL(string: urlString) else {
            serverInfo = "无效的URL: \(urlString)"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    serverInfo = "请求失败: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    serverInfo = "无效的响应"
                    return
                }
                
                serverInfo = "HTTP状态码: \(httpResponse.statusCode)\n"
                
                if httpResponse.statusCode != 200 {
                    serverInfo += "服务器返回错误"
                    return
                }
                
                guard let data = data else {
                    serverInfo += "无数据返回"
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let count = json?["count"] as? Int {
                        serverInfo += "图片数量: \(count)\n"
                    }
                    
                    if let imagesDir = json?["images_dir"] as? String {
                        serverInfo += "图片目录: \(imagesDir)\n\n"
                    }
                    
                    if let images = json?["images"] as? [[String: Any]] {
                        serverInfo += "最近10张图片:\n"
                        
                        for (index, image) in images.prefix(10).enumerated() {
                            if let filename = image["filename"] as? String,
                               let size = image["size"] as? Int,
                               let url = image["url"] as? String {
                                serverInfo += "\(index + 1). \(filename) (\(size) 字节)\n   URL: \(url)\n\n"
                            }
                        }
                    }
                } catch {
                    serverInfo += "解析JSON失败: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}