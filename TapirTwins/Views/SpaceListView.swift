import SwiftUI

struct SpaceListView: View {
    @StateObject private var viewModel = SpaceViewModel()
    @State private var showingCreateSpace = false
    @State private var showingJoinSpace = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else {
                    if viewModel.spaces.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "globe")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("还没有加入任何空间")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingCreateSpace = true
                            }) {
                                Text("创建空间")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            
                            Button(action: {
                                showingJoinSpace = true
                            }) {
                                Text("加入空间")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(viewModel.spaces) { space in
                                NavigationLink(destination: SpaceDetailView(spaceId: space.id)) {
                                    SpaceRow(space: space)
                                }
                                .onAppear {
                                    viewModel.fetchSpaces(forceRefresh: true)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .refreshable {
                            // 使用forceRefresh参数强制刷新数据
                            await refreshData()
                        }
                    }
                }
            }
            .navigationTitle("我的空间")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingCreateSpace = true
                        }) {
                            Label("创建空间", systemImage: "plus.circle")
                        }
                        
                        Button(action: {
                            showingJoinSpace = true
                        }) {
                            Label("加入空间", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSpace) {
                CreateSpaceView(isPresented: $showingCreateSpace, viewModel: viewModel)
            }
            .sheet(isPresented: $showingJoinSpace) {
                JoinSpaceView(isPresented: $showingJoinSpace, viewModel: viewModel)
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("错误"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
            .onAppear {
                viewModel.fetchSpaces()
            }
        }
    }
    
    // 刷新数据的异步函数
    private func refreshData() async {
        // 创建一个异步任务，以便可以等待它完成
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                // 使用forceRefresh参数强制刷新数据
                self.viewModel.fetchSpaces(forceRefresh: true)
                // 提供一个短暂的延迟以确保UI反馈
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    continuation.resume()
                }
            }
        }
    }
}

struct SpaceRow: View {
    let space: Space
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(space.name)
                .font(.headline)
            
            Text(space.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Text("成员: \(space.members.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("创建于: \(formattedDate(space.createdAt))")
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

struct CreateSpaceView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SpaceViewModel
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("空间信息")) {
                    TextField("空间名称", text: $name)
                    
                    TextField("空间描述", text: $description)
                        .frame(height: 100)
                }
            }
            .navigationTitle("创建新空间")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("创建") {
                    viewModel.createSpace(name: name, description: description)
                    isPresented = false
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

struct JoinSpaceView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SpaceViewModel
    @State private var inviteCode = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("输入邀请码")) {
                    TextField("空间邀请码", text: $inviteCode)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Text("请输入其他用户分享给你的空间邀请码")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("加入空间")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("加入") {
                    viewModel.joinSpace(inviteCode: inviteCode)
                    isPresented = false
                }
                .disabled(inviteCode.isEmpty)
            )
        }
    }
}

struct SpaceListView_Previews: PreviewProvider {
    static var previews: some View {
        SpaceListView()
    }
} 