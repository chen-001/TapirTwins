import SwiftUI

enum FormMode {
    case add
    case edit(Dream)
}

struct DreamFormView: View {
    let mode: FormMode
    let onComplete: (Bool) -> Void
    
    @StateObject private var viewModel = DreamViewModel()
    @State private var title = ""
    @State private var content = ""
    @State private var date = Date()
    
    @Environment(\.presentationMode) var presentationMode
    
    private var isEditMode: Bool {
        switch mode {
        case .add:
            return false
        case .edit:
            return true
        }
    }
    
    private var dreamId: String? {
        switch mode {
        case .add:
            return nil
        case .edit(let dream):
            return dream.id
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 梦幻背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.3, green: 0.2, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 星星效果（淡化处理）
                StarsView()
                    .opacity(0.3)
                
                VStack(spacing: 20) {
                    // 标题区域
                    VStack(alignment: .leading, spacing: 8) {
                        Text("梦境标题")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("", text: $title)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .accentColor(.white)
                            .placeholder(when: title.isEmpty) {
                                Text("输入梦境标题...")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.leading, 5)
                            }
                    }
                    .padding(.horizontal)
                    
                    // 日期选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("日期")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .colorScheme(.dark)
                            .accentColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // 内容区域
                    VStack(alignment: .leading, spacing: 8) {
                        Text("梦境内容")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("描述你的梦境...")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .padding(4)
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.black)
                                .accentColor(.blue)
                                .cornerRadius(8)
                                .opacity(content.isEmpty ? 0.7 : 1)
                        }
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle(isEditMode ? "编辑梦境" : "新梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "保存" : "添加") {
                        saveDream()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .foregroundColor(title.isEmpty || content.isEmpty ? .gray : .white)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
            )
            .alert(item: alertItem) { item in
                Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    private func setupInitialValues() {
        if case .edit(let dream) = mode {
            title = dream.title
            content = dream.content
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let dreamDate = dateFormatter.date(from: dream.date) {
                date = dreamDate
            }
        }
    }
    
    private func saveDream() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        if let id = dreamId {
            // 编辑现有梦境
            viewModel.updateDream(id: id, title: title, content: content, date: dateString) { success in
                onComplete(success)
            }
        } else {
            // 添加新梦境
            viewModel.addDream(title: title, content: content, date: dateString) { success in
                onComplete(success)
            }
        }
    }
    
    private var alertItem: Binding<AlertItem?> {
        Binding<AlertItem?>(
            get: {
                guard let errorMessage = viewModel.errorMessage else { return nil }
                return AlertItem(
                    title: "错误",
                    message: errorMessage
                )
            },
            set: { _ in viewModel.errorMessage = nil }
        )
    }
}

// 为TextField添加placeholder的扩展
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct DreamFormView_Previews: PreviewProvider {
    static var previews: some View {
        DreamFormView(mode: .add) { _ in }
    }
}
