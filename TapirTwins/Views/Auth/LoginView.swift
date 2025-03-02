import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showingRegister = false
    @State private var showingAPISettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("登录")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                // 图标
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.bottom, 30)
                
                // 登录表单
                VStack(spacing: 15) {
                    TextField("用户名", text: $viewModel.loginUsername)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.none)
                    
                    SecureField("密码", text: $viewModel.loginPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // 错误信息
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                
                // 登录按钮
                Button(action: {
                    viewModel.login()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                // 注册链接
                Button(action: {
                    showingRegister = true
                }) {
                    Text("没有账号？点击注册")
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                // API设置链接
                Button(action: {
                    showingAPISettings = true
                }) {
                    Text("自定义服务器")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRegister) {
                RegisterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAPISettings) {
                NavigationView {
                    APISettingsView()
                        .navigationBarItems(trailing: Button("关闭") {
                            showingAPISettings = false
                        })
                }
            }
        }
    }
}