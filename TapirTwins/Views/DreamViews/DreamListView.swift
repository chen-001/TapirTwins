import SwiftUI

struct DreamListView: View {
    @StateObject private var viewModel = DreamViewModel()
    @State private var showingAddDream = false
    @State private var showingFilterOptions = false
    @State private var selectedFilter: DreamFilter = .all
    @EnvironmentObject var authViewModel: AuthViewModel
    
    enum DreamFilter {
        case all, lastWeek, lastMonth
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
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
            .navigationBarItems(trailing: Button(action: {
                showingFilterOptions = true
            }) {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .font(.title2)
            })
            .sheet(isPresented: $showingAddDream) {
                DreamFormView(mode: .add, onComplete: { success in
                    showingAddDream = false
                    if success {
                        viewModel.fetchDreams()
                    }
                })
            }
            .actionSheet(isPresented: $showingFilterOptions) {
                ActionSheet(
                    title: Text("筛选梦境"),
                    buttons: [
                        .default(Text("全部")) { selectedFilter = .all },
                        .default(Text("最近一周")) { selectedFilter = .lastWeek },
                        .default(Text("最近一个月")) { selectedFilter = .lastMonth },
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
        .onAppear {
            viewModel.fetchDreams()
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
    
    private var filteredDreams: [Dream] {
        switch selectedFilter {
        case .all:
            return viewModel.dreams
        case .lastWeek:
            return viewModel.dreams.filter { isDateWithinLastWeek($0.date) }
        case .lastMonth:
            return viewModel.dreams.filter { isDateWithinLastMonth($0.date) }
        }
    }
    
    private func isDateWithinLastWeek(_ dateString: String) -> Bool {
        guard let date = formatDateToDate(dateString) else { return false }
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return date >= oneWeekAgo
    }
    
    private func isDateWithinLastMonth(_ dateString: String) -> Bool {
        guard let date = formatDateToDate(dateString) else { return false }
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        return date >= oneMonthAgo
    }
    
    private func formatDateToDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: dateString)
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
                
                // 添加梦境来源标签
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
                
                // 显示同步来源的用户名
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
