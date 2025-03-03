import SwiftUI
import UIKit

struct DreamListView: View {
    @StateObject private var viewModel = DreamViewModel()
    @State private var showingAddDream = false
    @State private var showingFilterOptions = false
    @State private var selectedFilter: DreamFilter = .all
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingWordCloud = false
    @State private var showingDreamReport = false
    @State private var showingReportOptions = false
    @State private var showingReportHistory = false
    @State private var showingCharacterStory = false
    @State private var showingCharacterInput = false
    @State private var characterName: String = ""
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    
    enum DreamFilter {
        case all, lastWeek, lastMonth
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // 搜索栏
                    searchBar
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    } else if viewModel.dreams.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "moon.stars")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("还没有梦境记录")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingAddDream = true
                            }) {
                                Text("记录梦境")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                    } else {
                        HStack(spacing: 12) {
                            Button(action: {
                                print("人物志按钮被点击")
                                showingCharacterInput = true
                                print("showingCharacterInput设置为true")
                            }) {
                                HStack {
                                    Image(systemName: "person.text.rectangle")
                                        .font(.system(size: 14))
                                    Text("人物志")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .foregroundColor(.white)
                                .background(Color.purple)
                                .cornerRadius(20)
                            }
                            
                            Button(action: {
                                print("梦境报告按钮被点击")
                                showingReportOptions = true
                                print("showingReportOptions设置为true")
                            }) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                        .font(.system(size: 14))
                                    Text("梦境报告")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .foregroundColor(.white)
                                .background(Color.green)
                                .cornerRadius(20)
                            }
                            
                            Button(action: {
                                showingReportHistory = true
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14))
                                    Text("报告历史")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                            
                            Menu {
                                Button(action: { selectedFilter = .all }) {
                                    Label("全部", systemImage: "list.bullet")
                                }
                                
                                Button(action: { selectedFilter = .lastWeek }) {
                                    Label("最近一周", systemImage: "calendar.badge.clock")
                                }
                                
                                Button(action: { selectedFilter = .lastMonth }) {
                                    Label("最近一个月", systemImage: "calendar")
                                }
                            } label: {
                                Image(systemName: "line.horizontal.3.decrease.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredDreams) { dream in
                                    NavigationLink(destination: DreamDetailView(dream: dream, onUpdate: {
                                        viewModel.fetchDreams()
                                    })) {
                                        DreamCard(dream: dream)
                                            .environmentObject(authViewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingAddDream = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("梦境记录")
            .navigationBarItems(
                leading: Button(action: {
                    showingWordCloud = true
                }) {
                    Image(systemName: "cloud")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingAddDream) {
                DreamFormView(mode: .add, onComplete: { success in
                    showingAddDream = false
                    if success {
                        viewModel.fetchDreams()
                    }
                })
            }
            .sheet(isPresented: $showingWordCloud) {
                DreamWordCloudView()
            }
            .sheet(isPresented: $showingDreamReport) {
                DreamReportView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingReportHistory) {
                ReportHistoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCharacterInput) {
                CharacterInputView(
                    viewModel: viewModel,
                    characterName: $characterName,
                    showingCharacterStory: $showingCharacterStory
                )
            }
            .sheet(isPresented: $showingCharacterStory) {
                CharacterStoryView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.fetchDreams()
        }
        .actionSheet(isPresented: $showingReportOptions) {
            ActionSheet(
                title: Text("选择报告时间范围"),
                message: Text("根据时间范围生成梦境报告"),
                buttons: [
                    .default(Text("最近一周")) {
                        updateReportTimeRange(.week)
                        showingDreamReport = true
                        print("开始生成梦境报告按钮被点击 - 最近一周选项")
                        viewModel.generateDreamReport { success in
                            print("报告生成完成，结果: \(success ? "成功" : "失败")")
                        }
                    },
                    .default(Text("最近一月")) {
                        updateReportTimeRange(.month)
                        showingDreamReport = true
                        print("开始生成梦境报告按钮被点击 - 最近一月选项")
                        viewModel.generateDreamReport { success in
                            print("报告生成完成，结果: \(success ? "成功" : "失败")")
                        }
                    },
                    .default(Text("最近一年")) {
                        updateReportTimeRange(.year)
                        showingDreamReport = true
                        print("开始生成梦境报告按钮被点击 - 最近一年选项")
                        viewModel.generateDreamReport { success in
                            print("报告生成完成，结果: \(success ? "成功" : "失败")")
                        }
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
        .alert(item: alertItem) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // 搜索栏视图
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("搜索梦境（标题、时间、内容）", text: $searchText)
                    .foregroundColor(.primary)
                    .onChange(of: searchText) { newValue in
                        viewModel.searchText = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.top, 8)
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
    
    private var filteredDreams: [Dream] {
        let dreams = viewModel.filteredDreams
        
        switch selectedFilter {
        case .all:
            return dreams
        case .lastWeek:
            let calendar = Calendar.current
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
            
            return dreams.filter { dream in
                if let dreamDate = ISO8601DateFormatter().date(from: dream.date) {
                    return dreamDate >= oneWeekAgo
                }
                return false
            }
        case .lastMonth:
            let calendar = Calendar.current
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
            
            return dreams.filter { dream in
                if let dreamDate = ISO8601DateFormatter().date(from: dream.date) {
                    return dreamDate >= oneMonthAgo
                }
                return false
            }
        }
    }
    
    private func updateReportTimeRange(_ range: ReportTimeRange) {
        var settings = UserSettings.load()
        settings.dreamReportTimeRange = range
        settings.save()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// 新增：人物志输入View
struct CharacterInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DreamViewModel
    @Binding var characterName: String
    @Binding var showingCharacterStory: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("请输入您要关注的人物名称")
                    .font(.headline)
                    .padding(.top, 20)
                
                TextField("例如：李哥、小明...", text: $characterName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Button(action: {
                    if !characterName.isEmpty {
                        // 先关闭输入框
                        presentationMode.wrappedValue.dismiss()
                        // 设置加载状态
                        viewModel.isCharacterStoryLoading = true
                        // 立即显示人物志页面（会显示加载中状态）
                        showingCharacterStory = true
                        // 然后开始生成
                        viewModel.generateCharacterStory(characterName: characterName) { _ in
                            // 成功或失败回调保持不变
                        }
                    }
                }) {
                    Text("生成人物志")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(characterName.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(characterName.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("人物志")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 新增：人物志故事展示View
struct CharacterStoryView: View {
    @ObservedObject var viewModel: DreamViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isCharacterStoryLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                                .padding()
                            
                            Text("貘婆婆正在奋笔疾书，请稍后哦")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .multilineTextAlignment(.center)
                            
                            Text("正在为您精心生成人物志...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                    } else if let characterStory = viewModel.currentCharacterStory {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.purple)
                                
                                Text("\(characterStory.characterName)的人物志")
                                    .font(.title)
                                    .bold()
                            }
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("基于\(characterStory.dreamsCount)个梦境记录的分析")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("生成时间：\(formatDate(characterStory.createdAt))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 16)
                            
                            MarkdownView(markdown: characterStory.content)
                        }
                        .padding()
                    } else {
                        Text("无法生成人物志，请重试。")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .navigationTitle("人物志")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct DreamReportView: View {
    @ObservedObject var viewModel: DreamViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isReportLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                                .padding()
                            
                            Text("貘婆婆正在赶来的路上，请稍等哦")
                                .font(.headline)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                            
                            Text("正在为您精心生成梦境报告...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                    } else if let report = viewModel.currentReport {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                
                                Text(getReportTitle(report.reportType))
                                    .font(.title)
                                    .bold()
                            }
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("基于\(report.dreamsCount)个梦境记录的统计")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("统计时间：\(formatDate(report.startDate)) - \(formatDate(report.endDate))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 16)
                            
                            MarkdownView(markdown: report.content)
                                .padding(.vertical, 8)
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        Text("未找到报告结果")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
            .navigationBarTitle("梦境报告", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func getReportTitle(_ reportType: String) -> String {
        switch reportType {
        case "week":
            return "梦境周报"
        case "month":
            return "梦境月报"
        case "year":
            return "梦境年报"
        default:
            return "梦境报告"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct DreamCard: View {
    let dream: Dream
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dream.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let spaceId = dream.spaceId {
                    Text("空间")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                if let mood = dream.mood {
                    Text(mood)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text(dream.content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.7))
                Text(formattedDate(dream.date))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if let spaceId = dream.spaceId, let username = dream.username {
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(username)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: date)
    }
}

struct DreamListView_Previews: PreviewProvider {
    static var previews: some View {
        DreamListView()
    }
}
