import SwiftUI

struct DreamDetailView: View {
    let dream: Dream
    let onUpdate: () -> Void
    
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @StateObject private var viewModel = DreamViewModel()
    @StateObject private var spaceViewModel = SpaceViewModel()
    @Environment(\.presentationMode) var presentationMode
    
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
                        .padding(.bottom, 30)
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
        .onAppear {
            spaceViewModel.fetchSpaces()
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
