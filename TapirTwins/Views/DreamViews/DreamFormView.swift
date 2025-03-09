import SwiftUI
import Combine

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
    @State private var keyboardHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    // 用于监听键盘事件
    @State private var keyboardPublisher = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillShowNotification)
        .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
    
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
                
                ScrollView {
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
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: ViewHeightKey.self,
                                                value: geo.frame(in: .local).size.height
                                            )
                                        }
                                    )
                                    .onPreferenceChange(ViewHeightKey.self) { height in
                                        self.contentHeight = height
                                    }
                            }
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // 添加额外的空间，确保键盘弹出时内容可以滚动到可见区域
                        Spacer()
                            .frame(height: max(0, keyboardHeight - 100))
                        
                        // 底部Logo（增强版）
                        VStack(spacing: 10) {
                            HStack(spacing: 6) {
                                // 左侧星星
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow.opacity(0.8))
                                
                                // 貘图像
                                Image("mo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 42, height: 42)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.purple, .blue]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(color: Color.purple.opacity(0.5), radius: 6)
                                
                                // 右侧星星
                                Image(systemName: "moon.stars")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow.opacity(0.8))
                            }
                            
                            Text("貘貘梦境TapirTwins")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 1)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.2, green: 0.2, blue: 0.4, opacity: 0.7),
                                            Color(red: 0.4, green: 0.3, blue: 0.6, opacity: 0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 4)
                        )
                        .padding(.bottom, 16)
                    }
                    .padding(.top, 20)
                    .animation(.default, value: keyboardHeight)
                }
                .onReceive(keyboardPublisher) { notification in
                    withAnimation {
                        if notification.name == UIResponder.keyboardWillShowNotification {
                            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                                self.keyboardHeight = keyboardFrame.height
                            }
                        } else {
                            self.keyboardHeight = 0
                        }
                    }
                }
                // 监听内容变化，自动滚动到底部
                .onChange(of: content) { newValue in
                    // 当内容变化且键盘显示时，确保滚动到底部
                    if keyboardHeight > 0 && !newValue.isEmpty {
                        withAnimation {
                            scrollOffset = contentHeight
                        }
                    }
                }
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

// 用于测量视图高度的PreferenceKey
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
