import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    Text("注册")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                    
                    // 图标
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                    
                    // 注册表单
                    VStack(spacing: 15) {
                        TextField("用户名", text: $viewModel.registerUsername)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocapitalization(.none)
                        
                        TextField("邮箱", text: $viewModel.registerEmail)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("密码", text: $viewModel.registerPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        SecureField("确认密码", text: $viewModel.confirmPassword)
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
                    
                    // 注册按钮
                    Button(action: {
                        viewModel.register()
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("注册")
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
                    
                    // 返回登录
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("已有账号？返回登录")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 