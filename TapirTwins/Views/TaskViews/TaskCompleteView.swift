import SwiftUI
import PhotosUI

struct TaskCompleteView: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
    
    var body: some View {
        ZStack {
            // 背景渐变
            themeGradient
                .opacity(0.3)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 任务信息
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
                        
                        Divider()
                            .background(themeColorDark.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("上传图片完成任务")
                                .font(.headline)
                                .foregroundColor(themeColorDark)
                            
                            Text("需要上传 \(task.requiredImages) 张图片")
                                .font(.subheadline)
                                .foregroundColor(Color.black.opacity(0.6))
                            
                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: task.requiredImages,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: "photo.stack")
                                        .font(.headline)
                                    Text("选择图片")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(themeColorDark)
                                .cornerRadius(10)
                            }
                            .onChange(of: selectedItems) { _, newItems in
                                // 清空selectedImages，因为loadTransferable是异步的，我们将在闭包中添加
                                selectedImages = []
                                loadImages(from: newItems)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // 显示选择的图片
                    if !selectedImages.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("已选择的图片")
                                .font(.headline)
                                .foregroundColor(themeColorDark)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(0..<selectedImages.count, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(themeColorDark, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    // 提交按钮
                    Button(action: submitTask) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                Text("提交完成")
                                    .font(.headline)
                                    .bold()
                            }
                            Spacer()
                        }
                        .padding()
                        .background(selectedImages.count == task.requiredImages ? themeColorDark : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(selectedImages.count != task.requiredImages || isSubmitting)
                    .padding(.vertical)
                }
                .padding()
            }
        }
        .navigationTitle("完成任务")
        .navigationBarItems(leading: Button("取消") {
            presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(themeColorDark))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSubmitting ? "处理中" : "提示"),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    private func submitTask() {
        guard selectedImages.count == task.requiredImages else {
            alertMessage = "请上传 \(task.requiredImages) 张图片"
            showAlert = true
            return
        }
        
        isSubmitting = true
        alertMessage = "正在上传图片，请稍候..."
        showAlert = true
        
        viewModel.completeTask(id: task.id, images: selectedImages) { success in
            isSubmitting = false
            
            if success {
                alertMessage = "任务完成！"
                showAlert = true
                
                // 延迟关闭页面，让用户看到成功消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                alertMessage = viewModel.errorMessage ?? "提交失败，请重试"
                showAlert = true
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.selectedImages.append(image)
                        }
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }
}

struct TaskCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        let task = Task(
            id: "1",
            title: "测试任务",
            description: "这是一个测试任务",
            dueDate: "2023-01-01T00:00:00.000Z",
            createdAt: "2023-01-01T00:00:00.000Z",
            updatedAt: "2023-01-01T00:00:00.000Z",
            completedToday: false,
            requiredImages: 2,
            spaceId: "space1",
            submitterId: "user1",
            status: TaskStatus.pending
        )
        
        return NavigationView {
            TaskCompleteView(task: task, viewModel: TaskViewModel())
        }
    }
}
