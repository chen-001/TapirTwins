import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var spaceViewModel = SpaceViewModel()
    @State private var showingSpaceSelector = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("梦境设置")) {
                    VStack(alignment: .leading) {
                        Text("默认分享空间")
                            .font(.headline)
                        
                        Button(action: {
                            showingSpaceSelector = true
                        }) {
                            HStack {
                                if let defaultSpaceId = viewModel.defaultShareSpaceId,
                                   let space = spaceViewModel.spaces.first(where: { $0.id == defaultSpaceId }) {
                                    Text(space.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("未设置")
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("设置后，新创建的梦境将自动分享到该空间")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    
                    if viewModel.defaultShareSpaceId != nil {
                        Button(action: {
                            viewModel.updateDefaultShareSpace(spaceId: nil)
                        }) {
                            Text("清除默认分享空间")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Divider()
                    
                    Toggle(isOn: $viewModel.dreamReminderEnabled) {
                        VStack(alignment: .leading) {
                            Text("每日梦境提醒")
                                .font(.headline)
                            
                            Text("在指定时间提醒你记录昨晚的梦境")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: viewModel.dreamReminderEnabled) { newValue in
                        if newValue {
                            // 如果用户启用了提醒，检查并请求通知权限
                            UNUserNotificationCenter.current().getNotificationSettings { settings in
                                DispatchQueue.main.async {
                                    if settings.authorizationStatus != .authorized {
                                        viewModel.requestNotificationPermission { granted in
                                            if !granted {
                                                // 若用户拒绝了权限，显示提示
                                                viewModel.errorMessage = "无法发送提醒，请在设备设置中允许应用发送通知。"
                                            }
                                        }
                                    } else {
                                        // 权限已获取，更新设置
                                        viewModel.updateDreamReminderSettings(
                                            enabled: newValue,
                                            time: viewModel.dreamReminderTime
                                        )
                                    }
                                }
                            }
                        } else {
                            // 用户禁用了提醒，直接更新设置
                            viewModel.updateDreamReminderSettings(
                                enabled: false,
                                time: viewModel.dreamReminderTime
                            )
                        }
                    }
                    
                    if viewModel.dreamReminderEnabled {
                        DatePicker(
                            "提醒时间",
                            selection: $viewModel.dreamReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: viewModel.dreamReminderTime) { newValue in
                            viewModel.updateDreamReminderSettings(
                                enabled: viewModel.dreamReminderEnabled,
                                time: newValue
                            )
                        }
                    }
                    
                    // 新增：梦境分析时间范围设置
                    VStack(alignment: .leading) {
                        Text("梦境分析时间范围")
                            .font(.headline)
                        
                        Picker("", selection: $viewModel.dreamAnalysisTimeRange) {
                            ForEach(AnalysisTimeRange.allCases, id: \.self) { timeRange in
                                Text(timeRange.displayName).tag(timeRange)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.dreamAnalysisTimeRange) { newValue in
                            viewModel.updateDreamAnalysisTimeRange(timeRange: newValue)
                        }
                        
                        Text("设置分析多长时间内的梦境记录")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    
                    // 新增：梦境报告类型设置
                    VStack(alignment: .leading) {
                        Text("梦境报告类型")
                            .font(.headline)
                        
                        Picker("", selection: $viewModel.dreamReportTimeRange) {
                            ForEach(ReportTimeRange.allCases, id: \.self) { reportType in
                                Text(reportType.displayName).tag(reportType)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.dreamReportTimeRange) { newValue in
                            viewModel.updateDreamReportTimeRange(timeRange: newValue)
                        }
                        
                        Text("设置梦境报告类型")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    
                    // 新增：梦境报告长度设置
                    VStack(alignment: .leading) {
                        Text("梦境报告长度")
                            .font(.headline)
                        
                        Picker("", selection: $viewModel.dreamReportLength) {
                            ForEach(ReportLength.allCases, id: \.self) { length in
                                Text(length.displayName).tag(length)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.dreamReportLength) { newValue in
                            viewModel.updateDreamReportLength(length: newValue)
                        }
                        
                        Text("设置梦境报告详细程度")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    
                    // 新增：梦境记录者筛选设置
                    Toggle(isOn: $viewModel.onlySelfRecordings) {
                        VStack(alignment: .leading) {
                            Text("梦境报告仅传入我记录的梦境")
                                .font(.headline)
                            
                            Text("开启后，仅分析由您自己记录的梦境")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                    }
                    .onChange(of: viewModel.onlySelfRecordings) { newValue in
                        viewModel.updateOnlySelfRecordings(enabled: newValue)
                    }
                    .padding(.vertical, 8)
                    
                    // 添加灵动岛陪伴模式设置
                    if #available(iOS 16.1, *) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $viewModel.companionModeEnabled) {
                                VStack(alignment: .leading) {
                                    Text("貘婆婆灵动岛陪伴")
                                        .font(.headline)
                                    
                                    Text("在灵动岛上显示貘婆婆的美好诗句")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            if viewModel.companionModeEnabled {
                                Button(action: {
                                    viewModel.refreshCompanionSignature()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("刷新签名")
                                    }
                                    .foregroundColor(.blue)
                                }
                                .padding(.leading, 8)
                            }
                        }
                    }
                }
                
                Section(header: Text("AI内容设置")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("解梦字数")
                            .font(.headline)
                        
                        HStack {
                            Slider(value: Binding<Double>(
                                get: { Double(viewModel.interpretationLength) },
                                set: { viewModel.interpretationLength = Int($0) }
                            ), in: 200...800, step: 50)
                            .onChange(of: viewModel.interpretationLength) { newValue in
                                viewModel.updateAIOutputLengths(
                                    interpretation: viewModel.interpretationLength,
                                    continuation: viewModel.continuationLength,
                                    prediction: viewModel.predictionLength
                                )
                            }
                            
                            Text("\(viewModel.interpretationLength)字")
                                .foregroundColor(.gray)
                                .frame(width: 60, alignment: .trailing)
                        }
                        
                        Text("设置AI生成解梦内容的字数")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("续写字数")
                            .font(.headline)
                        
                        HStack {
                            Slider(value: Binding<Double>(
                                get: { Double(viewModel.continuationLength) },
                                set: { viewModel.continuationLength = Int($0) }
                            ), in: 200...800, step: 50)
                            .onChange(of: viewModel.continuationLength) { newValue in
                                viewModel.updateAIOutputLengths(
                                    interpretation: viewModel.interpretationLength,
                                    continuation: viewModel.continuationLength,
                                    prediction: viewModel.predictionLength
                                )
                            }
                            
                            Text("\(viewModel.continuationLength)字")
                                .foregroundColor(.gray)
                                .frame(width: 60, alignment: .trailing)
                        }
                        
                        Text("设置AI生成续写内容的字数")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预言字数")
                            .font(.headline)
                        
                        HStack {
                            Slider(value: Binding<Double>(
                                get: { Double(viewModel.predictionLength) },
                                set: { viewModel.predictionLength = Int($0) }
                            ), in: 200...800, step: 50)
                            .onChange(of: viewModel.predictionLength) { newValue in
                                viewModel.updateAIOutputLengths(
                                    interpretation: viewModel.interpretationLength,
                                    continuation: viewModel.continuationLength,
                                    prediction: viewModel.predictionLength
                                )
                            }
                            
                            Text("\(viewModel.predictionLength)字")
                                .foregroundColor(.gray)
                                .frame(width: 60, alignment: .trailing)
                        }
                        
                        Text("设置AI生成预言内容的字数")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        // 重置为默认字数
                        viewModel.updateAIOutputLengths(
                            interpretation: 400,
                            continuation: 400,
                            prediction: 400
                        )
                    }) {
                        Text("恢复默认字数")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("服务器设置")) {
                    NavigationLink(destination: APISettingsView()) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.blue)
                            Text("API服务器设置")
                        }
                    }
                    
                    NavigationLink {
                        ImageServerDebugViewWrapper()
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                            Text("图片服务器调试")
                        }
                    }
                    
                    HStack {
                        Text("当前服务器")
                        Spacer()
                        Text(APIConfig.baseURL)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingSpaceSelector) {
                SpaceSelectorView(
                    spaces: spaceViewModel.spaces,
                    selectedSpaceId: viewModel.defaultShareSpaceId,
                    onSelect: { spaceId in
                        viewModel.updateDefaultShareSpace(spaceId: spaceId)
                        showingSpaceSelector = false
                    },
                    onCancel: {
                        showingSpaceSelector = false
                    }
                )
            }
            .onAppear {
                spaceViewModel.fetchSpaces()
                viewModel.fetchSettings()
            }
            .onDisappear {
                // 页面消失时，确保灵动岛状态一致
                if #available(iOS 16.1, *) {
                    // 延迟执行，确保视图完全消失
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if viewModel.companionModeEnabled {
                            DreamCompanionManager.shared.startCompanionMode()
                        }
                    }
                }
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
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

// 图片服务器调试视图包装器
struct ImageServerDebugViewWrapper: View {
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
        .navigationTitle("图片服务器调试")
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

struct SpaceSelectorView: View {
    let spaces: [Space]
    let selectedSpaceId: String?
    let onSelect: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                if spaces.isEmpty {
                    Text("你还没有加入任何空间")
                        .foregroundColor(.gray)
                } else {
                    ForEach(spaces) { space in
                        Button(action: {
                            onSelect(space.id)
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
            .navigationTitle("选择默认空间")
            .navigationBarItems(
                trailing: Button("取消") {
                    onCancel()
                }
            )
        }
    }
}