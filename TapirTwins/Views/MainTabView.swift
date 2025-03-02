import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DreamListView()
                .tabItem {
                    Label("梦境", systemImage: "moon.stars")
                }
                .tag(0)
            
            TaskListView()
                .tabItem {
                    Label("任务", systemImage: "checklist")
                }
                .tag(1)
            
            SpaceListView()
                .tabItem {
                    Label("空间", systemImage: "person.2")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
            
            ProfileView(viewModel: authViewModel)
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}
