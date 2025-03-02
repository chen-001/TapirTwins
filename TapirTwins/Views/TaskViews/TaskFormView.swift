import SwiftUI

enum TaskFormMode {
    case add
    case edit(Task)
}

struct TaskFormView: View {
    let mode: TaskFormMode
    @ObservedObject var viewModel: TaskViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate: Date?
    @State private var showDatePicker = false
    @State private var requiredImages = 1
    @State private var isSubmitting = false
    
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
    
    private var isEditMode: Bool {
        switch mode {
        case .add:
            return false
        case .edit:
            return true
        }
    }
    
    private var task: Task? {
        switch mode {
        case .add:
            return nil
        case .edit(let task):
            return task
        }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            themeGradient
                .opacity(0.3)
                .ignoresSafeArea()
            
            Form {
                Section(header: Text("任务信息").foregroundColor(themeColorDark)) {
                    TextField("任务标题", text: $title)
                        .padding(.vertical, 8)
                        .accentColor(themeColorDark)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("任务描述（可选）")
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(.horizontal, -4)
                            .accentColor(themeColorDark)
                    }
                }
                .listRowBackground(Color.white.opacity(0.7))
                
                Section(header: Text("截止日期").foregroundColor(themeColorDark)) {
                    Toggle(isOn: Binding<Bool>(
                        get: { dueDate != nil },
                        set: { if !$0 { dueDate = nil } }
                    )) {
                        Text("设置截止日期")
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeColorDark))
                    
                    if dueDate != nil || showDatePicker {
                        DatePicker(
                            "选择日期",
                            selection: Binding<Date>(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .accentColor(themeColorDark)
                        .onAppear {
                            if dueDate == nil {
                                dueDate = Date()
                            }
                            showDatePicker = true
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.7))
                
                Section(header: Text("图片要求").foregroundColor(themeColorDark)) {
                    Stepper(value: $requiredImages, in: 1...10) {
                        Text("需要上传 \(requiredImages) 张图片")
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                }
                .listRowBackground(Color.white.opacity(0.7))
                
                Section {
                    Button(action: submitForm) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isEditMode ? "保存修改" : "创建任务")
                                    .bold()
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(themeColorDark)
                        .cornerRadius(8)
                    }
                    .disabled(title.isEmpty || isSubmitting)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(isEditMode ? "编辑任务" : "新建任务")
        .navigationBarItems(leading: Button("取消") {
            presentationMode.wrappedValue.dismiss()
        }
        .foregroundColor(themeColorDark))
        .onAppear {
            if let task = task {
                title = task.title
                description = task.description ?? ""
                
                if let dueDateString = task.dueDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dueDate = dateFormatter.date(from: dueDateString)
                    showDatePicker = dueDate != nil
                }
                
                requiredImages = task.requiredImages
            }
        }
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
    
    private func submitForm() {
        guard !title.isEmpty else { return }
        
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let dueDateString = dueDate != nil ? dateFormatter.string(from: dueDate!) : nil
        
        if isEditMode, let task = task {
            viewModel.updateTask(
                id: task.id,
                title: title,
                description: description.isEmpty ? nil : description,
                dueDate: dueDateString,
                requiredImages: requiredImages,
                spaceId: task.spaceId
            ) { success in
                isSubmitting = false
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            viewModel.addTask(
                title: title,
                description: description.isEmpty ? nil : description,
                dueDate: dueDateString,
                requiredImages: requiredImages,
                spaceId: nil
            ) { success in
                isSubmitting = false
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.fetchTasks()
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct TaskFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskFormView(mode: .add, viewModel: TaskViewModel())
        }
    }
}
