import SwiftUI

struct APISettingsView: View {
    @StateObject private var viewModel = APISettingsViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("API服务器设置")) {
                TextField("API服务器地址", text: $viewModel.apiURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                
                Button(action: {
                    viewModel.saveAPISettings()
                }) {
                    Text("保存设置")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    viewModel.resetToDefault()
                }) {
                    Text("重置为默认地址")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            Section(header: Text("说明")) {
                Text("修改API服务器地址后，您需要重新登录应用。")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Text("默认地址: \(APIConfig.defaultBaseURL)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Link("配置服务器的代码请参照TapirTwins后端仓库", destination: URL(string: "https://github.com/chen-001/TapirTwins_backend")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .navigationTitle("API设置")
        .alert(viewModel.isSuccess ? "设置成功" : "设置失败", isPresented: $viewModel.showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            // 加载当前设置
            viewModel.loadSettings()
        }
    }
}

struct APISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            APISettingsView()
        }
    }
}
