import SwiftUI

struct DreamDetailView: View {
    let dream: Dream
    let onUpdate: () -> Void
    
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingInterpretationSheet = false
    @State private var showingContinuationSheet = false
    @State private var showingPredictionSheet = false
    @State private var showingDeleteConfirmation = false
    @StateObject private var viewModel = DreamViewModel()
    @StateObject private var spaceViewModel = SpaceViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // 显示AI内容的状态
    @State private var showInterpretations = true
    @State private var showContinuations = true
    @State private var showPredictions = true
    
    // 用于更新的当前梦境
    @State private var currentDream: Dream
    
    // 直接访问API服务
    private let apiService = APIService.shared
    
    init(dream: Dream, onUpdate: @escaping () -> Void) {
        self.dream = dream
        self.onUpdate = onUpdate
        self._currentDream = State(initialValue: dream)
    }
    
    var body: some View {
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
            
            // 星星效果
            StarsView()
                .opacity(0.5)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题
                    Text(dream.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // 日期
                    HStack {
                        Image(systemName: "moon.stars")
                            .foregroundColor(.yellow.opacity(0.8))
                            .font(.system(size: 18))
                        Text(formatDate(dream.date))
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.vertical, 5)
                    
                    // 如果梦境来自空间且有用户名，显示用户名
                    if let spaceId = dream.spaceId, let username = dream.username {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue.opacity(0.8))
                                .font(.system(size: 16))
                            Text("记录者: \(username)")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.vertical, 5)
                    }
                    
                    // 分隔线
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.vertical, 10)
                    
                    // 内容
                    Text(dream.content)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(8)
                        .padding(.bottom, 10)
                    
                    // AI功能按钮
                    HStack(spacing: 10) {
                        // 解梦按钮
                        Button(action: {
                            showingInterpretationSheet = true
                        }) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 18))
                                Text("解梦")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        // 续写按钮
                        Button(action: {
                            showingContinuationSheet = true
                        }) {
                            HStack {
                                Image(systemName: "text.book.closed")
                                    .font(.system(size: 18))
                                Text("续写")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.cyan.opacity(0.6), Color.green.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        // 预言按钮
                        Button(action: {
                            showingPredictionSheet = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18))
                                Text("预言")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.red.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // AI解梦结果部分
                    if let interpretations = currentDream.dreamInterpretations, !interpretations.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(.purple)
                                Text("解梦历史")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            
                            VStack(spacing: 15) {
                                ForEach(interpretations) { interpretation in
                                    DreamInterpretationView(interpretation: interpretation)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.top, 15)
                    }
                    
                    // AI续写结果部分
                    if let continuations = currentDream.dreamContinuations, !continuations.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "text.book.closed")
                                    .foregroundColor(.cyan)
                                Text("续写历史")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            
                            VStack(spacing: 15) {
                                ForEach(continuations) { continuation in
                                    DreamContinuationView(continuation: continuation)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.top, 15)
                    }
                    
                    // 预言结果部分
                    if let predictions = currentDream.dreamPredictions, !predictions.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("预言历史")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            
                            VStack(spacing: 15) {
                                ForEach(predictions) { prediction in
                                    DreamPredictionView(prediction: prediction)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.top, 15)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.2))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
                )
                .padding(.horizontal, 5)
                .padding(.vertical, 10)
            }
        }
        .navigationBarTitle("梦境详情", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("分享到空间", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("删除", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            DreamFormView(mode: .edit(dream)) { success in
                if success {
                    onUpdate()
                    presentationMode.wrappedValue.dismiss()
                }
                showingEditSheet = false
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareDreamView(
                dream: dream,
                viewModel: viewModel,
                spaceViewModel: spaceViewModel,
                onShare: {
                    showingShareSheet = false
                }
            )
        }
        .sheet(isPresented: $showingInterpretationSheet) {
            InterpretationStyleSheet(
                dream: dream,
                viewModel: viewModel,
                onComplete: { success in
                    if success {
                        onUpdate()
                    }
                    showingInterpretationSheet = false
                }
            )
        }
        .sheet(isPresented: $showingContinuationSheet) {
            ContinuationStyleSheet(
                dream: dream,
                viewModel: viewModel,
                onComplete: { success in
                    if success {
                        onUpdate()
                    }
                    showingContinuationSheet = false
                }
            )
        }
        .sheet(isPresented: $showingPredictionSheet) {
            PredictionStyleSheet(
                dream: dream,
                viewModel: viewModel,
                onComplete: { success in
                    if success {
                        onUpdate()
                    }
                    showingPredictionSheet = false
                }
            )
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("删除确认"),
                message: Text("确定要删除这个梦境记录吗？此操作不可撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    deleteDream()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("貘公正在赶来的路上，请稍等片刻")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    }
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
        .onAppear {
            spaceViewModel.fetchSpaces()
            
            // 确保viewModel中有当前梦境的数据
            viewModel.dreams = [currentDream]
            
            // 加载AI内容
            loadDreamAIContent()
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: date)
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
    
    // 加载AI内容
    private func loadDreamAIContent() {
        print("开始加载梦境AI内容...")
        viewModel.loadDreamAIContent(dreamId: dream.id) { success in
            print("加载梦境AI内容结果: \(success ? "成功" : "失败")")
            
            // 如果成功，尝试从viewModel中获取更新后的梦境对象
            if success, let updatedDream = self.viewModel.dreams.first(where: { $0.id == self.dream.id }) {
                print("找到更新后的梦境对象，更新currentDream")
                DispatchQueue.main.async {
                    self.currentDream = updatedDream
                    
                    // 确保在加载到数据后确保内容展开
                    if (updatedDream.dreamInterpretations?.count ?? 0) > 0 {
                        self.showInterpretations = true
                    }
                    if (updatedDream.dreamContinuations?.count ?? 0) > 0 {
                        self.showContinuations = true
                    }
                    if (updatedDream.dreamPredictions?.count ?? 0) > 0 {
                        self.showPredictions = true
                    }
                }
            } else {
                print("未找到更新后的梦境对象，尝试手动更新currentDream的AI内容")
                
                // 手动获取梦境的AI内容并更新currentDream
                self.fetchAndUpdateDreamAIContent()
            }
        }
    }
    
    // 手动获取梦境AI内容并更新currentDream
    private func fetchAndUpdateDreamAIContent() {
        let dispatchGroup = DispatchGroup()
        
        // 使用主线程隔离的变量来保存更新
        var interpretations: [DreamInterpretation] = []
        var continuations: [DreamContinuation] = []
        var predictions: [DreamPrediction] = []
        
        // 获取解梦历史
        dispatchGroup.enter()
        apiService.request(endpoint: "dream_interpretations?dream_id=\(dream.id)", method: "GET") { (result: Result<[DreamInterpretation], APIError>) in
            defer { dispatchGroup.leave() }
            
            if case .success(let fetchedInterpretations) = result {
                print("手动获取解梦历史成功: \(fetchedInterpretations.count)条记录")
                interpretations = fetchedInterpretations
            }
        }
        
        // 获取续写历史
        dispatchGroup.enter()
        apiService.request(endpoint: "dream_continuations?dream_id=\(dream.id)", method: "GET") { (result: Result<[DreamContinuation], APIError>) in
            defer { dispatchGroup.leave() }
            
            if case .success(let fetchedContinuations) = result {
                print("手动获取续写历史成功: \(fetchedContinuations.count)条记录")
                continuations = fetchedContinuations
            }
        }
        
        // 获取预测历史
        dispatchGroup.enter()
        apiService.request(endpoint: "dream_predictions?dream_id=\(dream.id)", method: "GET") { (result: Result<[DreamPrediction], APIError>) in
            defer { dispatchGroup.leave() }
            
            if case .success(let fetchedPredictions) = result {
                print("手动获取预测历史成功: \(fetchedPredictions.count)条记录")
                predictions = fetchedPredictions
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("手动更新currentDream完成")
            
            // 在主线程上一次性更新
            var updatedDream = self.currentDream
            updatedDream.dreamInterpretations = interpretations
            updatedDream.dreamContinuations = continuations
            updatedDream.dreamPredictions = predictions
            
            // 更新currentDream
            self.currentDream = updatedDream
            
            // 更新显示状态
            if !interpretations.isEmpty {
                self.showInterpretations = true
            }
            if !continuations.isEmpty {
                self.showContinuations = true
            }
            if !predictions.isEmpty {
                self.showPredictions = true
            }
            
            // 确保viewModel中也有更新的数据
            if !self.viewModel.dreams.isEmpty {
                if let index = self.viewModel.dreams.firstIndex(where: { $0.id == self.dream.id }) {
                    self.viewModel.dreams[index] = updatedDream
                } else {
                    self.viewModel.dreams.append(updatedDream)
                }
            } else {
                self.viewModel.dreams = [updatedDream]
            }
        }
    }
    
    // 删除梦境
    private func deleteDream() {
        print("开始删除梦境...")
        viewModel.deleteDream(id: dream.id) { success in
            print("删除梦境结果: \(success ? "成功" : "失败")")
            if success {
                print("梦境删除成功，刷新数据...")
                self.onUpdate()
            } else {
                print("梦境删除失败: \(self.viewModel.errorMessage ?? "未知错误")")
            }
        }
    }
}

// 解梦风格选择sheet
struct InterpretationStyleSheet: View {
    let dream: Dream
    @ObservedObject var viewModel: DreamViewModel
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.3, green: 0.2, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("选择解梦风格")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("AI将以不同风格解析你的梦境")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 20)
                    
                    // 风格选择按钮
                    styleButton(title: "玄学版", icon: "sparkles.square.filled.on.square", color: .purple) {
                        interpretDream(style: .mystic)
                    }
                    
                    styleButton(title: "科学版", icon: "brain.head.profile", color: .blue) {
                        interpretDream(style: .scientific)
                    }
                    
                    styleButton(title: "幽默版", icon: "face.smiling", color: .orange) {
                        interpretDream(style: .humorous)
                    }
                    
                    styleButton(title: "甄嬛风", icon: "crown.fill", color: .red) {
                        interpretDream(style: .zhenHuan1)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("解梦", displayMode: .inline)
            .navigationBarItems(trailing: Button("取消") {
                onComplete(false)
            })
        }
    }
    
    private func styleButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.6))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    private func interpretDream(style: DeepSeekStyle) {
        print("开始解梦，风格: \(style.rawValue)")
        viewModel.interpretDream(dream: dream, style: style) { success in
            print("解梦结果: \(success ? "成功" : "失败")")
            if success {
                print("解梦成功，准备更新UI")
                // 通知父视图更新
                DispatchQueue.main.async {
                    self.onComplete(true)
                }
            } else {
                print("解梦失败: \(self.viewModel.errorMessage ?? "未知错误")")
                DispatchQueue.main.async {
                    self.onComplete(false)
                }
            }
        }
    }
}

// 续写风格选择sheet
struct ContinuationStyleSheet: View {
    let dream: Dream
    @ObservedObject var viewModel: DreamViewModel
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.3, green: 0.2, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("选择续写风格")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("AI将以不同风格续写你的梦境")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 20)
                    
                    // 风格选择按钮
                    styleButton(title: "喜剧", icon: "theatermasks.fill", color: .yellow) {
                        continueDream(style: .comedy)
                    }
                    
                    styleButton(title: "悲剧", icon: "cloud.heavyrain.fill", color: .indigo) {
                        continueDream(style: .tragedy)
                    }
                    
                    styleButton(title: "悬疑", icon: "magnifyingglass.circle.fill", color: .green) {
                        continueDream(style: .mystery)
                    }
                    
                    styleButton(title: "科幻", icon: "airplane.circle.fill", color: .cyan) {
                        continueDream(style: .scifi)
                    }
                    
                    styleButton(title: "伦理", icon: "books.vertical.fill", color: .mint) {
                        continueDream(style: .ethical)
                    }
                    
                    styleButton(title: "甄嬛风", icon: "crown.fill", color: .red) {
                        continueDream(style: .zhenHuan2)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("续写", displayMode: .inline)
            .navigationBarItems(trailing: Button("取消") {
                onComplete(false)
            })
        }
    }
    
    private func styleButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.6))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    private func continueDream(style: DeepSeekStyle) {
        print("开始续写梦境，风格: \(style.rawValue)")
        viewModel.continueDream(dream: dream, style: style) { success in
            print("续写结果: \(success ? "成功" : "失败")")
            if success {
                print("续写成功，准备更新UI")
                // 通知父视图更新
                DispatchQueue.main.async {
                    self.onComplete(true)
                }
            } else {
                print("续写失败: \(self.viewModel.errorMessage ?? "未知错误")")
                DispatchQueue.main.async {
                    self.onComplete(false)
                }
            }
        }
    }
}

struct ShareDreamView: View {
    let dream: Dream
    @ObservedObject var viewModel: DreamViewModel
    @ObservedObject var spaceViewModel: SpaceViewModel
    let onShare: () -> Void
    
    @State private var selectedSpaceId: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var saveAsDefault = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择要分享到的空间")) {
                    if spaceViewModel.spaces.isEmpty {
                        Text("你还没有加入任何空间")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(spaceViewModel.spaces) { space in
                            Button(action: {
                                selectedSpaceId = space.id
                            }) {
                                HStack {
                                    Text(space.name)
                                    Spacer()
                                    if selectedSpaceId == space.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                Section {
                    Toggle("设为默认分享空间", isOn: $saveAsDefault)
                        .disabled(selectedSpaceId == nil)
                }
                
                Section {
                    Button(action: {
                        shareDream()
                    }) {
                        Text("分享")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(selectedSpaceId != nil ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(selectedSpaceId == nil)
                }
            }
            .navigationTitle("分享梦境")
            .navigationBarItems(
                trailing: Button("取消") {
                    onShare()
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("提示"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("确定")) {
                        if alertMessage.contains("成功") {
                            onShare()
                        }
                    }
                )
            }
        }
    }
    
    private func shareDream() {
        guard let spaceId = selectedSpaceId else { return }
        
        viewModel.shareDreamToSpace(dream: dream, spaceId: spaceId) { success in
            if success {
                alertMessage = "梦境已成功分享到空间"
                
                // 如果用户选择了设为默认，则更新设置
                if saveAsDefault {
                    // 更新本地设置
                    var settings = UserSettings.load()
                    settings.defaultShareSpaceId = spaceId
                    settings.save()
                    
                    // 更新服务器设置
                    let settingsViewModel = SettingsViewModel()
                    settingsViewModel.updateDefaultShareSpace(spaceId: spaceId)
                }
            } else {
                alertMessage = viewModel.errorMessage ?? "分享失败，请稍后重试"
            }
            showingAlert = true
        }
    }
}

// 预言风格选择sheet
struct PredictionStyleSheet: View {
    let dream: Dream
    @ObservedObject var viewModel: DreamViewModel
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.3, green: 0.2, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("选择预言时间范围")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("AI将预测不同时间段内可能发生的事件")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 20)
                    
                    // 时间范围选择按钮
                    styleButton(title: "今日预言", icon: "sun.max.fill", color: .orange) {
                        predictDream(style: .predictToday)
                    }
                    
                    styleButton(title: "未来一个月", icon: "calendar", color: .blue) {
                        predictDream(style: .predictMonth)
                    }
                    
                    styleButton(title: "未来一年", icon: "calendar.badge.clock", color: .purple) {
                        predictDream(style: .predictYear)
                    }
                    
                    styleButton(title: "未来五年", icon: "hourglass", color: .green) {
                        predictDream(style: .predictFiveYears)
                    }
                    
                    styleButton(title: "甄嬛风", icon: "crown.fill", color: .red) {
                        predictDream(style: .zhenHuan3)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("预言", displayMode: .inline)
            .navigationBarItems(trailing: Button("取消") {
                onComplete(false)
            })
        }
    }
    
    private func styleButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.6))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    private func predictDream(style: DeepSeekStyle) {
        print("开始预言，时间范围: \(style.rawValue)")
        viewModel.predictFromDream(id: dream.id, style: style, completion: { success in
            print("预言结果: \(success ? "成功" : "失败")")
            if success {
                print("预言成功，准备更新UI")
                // 通知父视图更新
                DispatchQueue.main.async {
                    self.onComplete(true)
                }
            } else {
                print("预言失败: \(self.viewModel.errorMessage ?? "未知错误")")
                DispatchQueue.main.async {
                    self.onComplete(false)
                }
            }
        })
    }
}

struct DreamDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DreamDetailView(
                dream: Dream(
                    id: "1",
                    title: "梦见飞翔",
                    content: "我梦见自己在天空中飞翔，俯瞰大地，感觉非常自由。",
                    date: "2025-02-28",
                    createdAt: "2025-02-28T12:00:00Z"
                ),
                onUpdate: {}
            )
        }
    }
}
