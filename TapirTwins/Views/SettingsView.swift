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