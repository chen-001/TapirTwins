import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // 登录表单
    @Published var loginUsername = ""
    @Published var loginPassword = ""
    
    // 注册表单
    @Published var registerUsername = ""
    @Published var registerPassword = ""
    @Published var registerEmail = ""
    @Published var confirmPassword = ""
    
    private let authService = AuthService.shared
    
    init() {
        // 检查是否已登录
        checkAuthentication()
    }
    
    // 检查认证状态
    func checkAuthentication() {
        if authService.isLoggedIn, let user = authService.getCurrentUser() {
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // 登录
    func login() {
        guard !loginUsername.isEmpty, !loginPassword.isEmpty else {
            self.error = "用户名和密码不能为空"
            return
        }
        
        isLoading = true
        error = nil
        
        authService.login(username: loginUsername, password: loginPassword) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let authResponse):
                    self?.currentUser = authResponse.user
                    self?.isAuthenticated = true
                    self?.clearLoginForm()
                case .failure(let error):
                    switch error {
                    case .serverError(let message):
                        self?.error = message
                    case .unauthorized:
                        self?.error = "用户名或密码错误"
                    default:
                        self?.error = "登录失败，请稍后重试"
                    }
                }
            }
        }
    }
    
    // 注册
    func register() {
        guard !registerUsername.isEmpty, !registerPassword.isEmpty, !registerEmail.isEmpty else {
            self.error = "所有字段都不能为空"
            return
        }
        
        guard registerPassword == confirmPassword else {
            self.error = "两次输入的密码不一致"
            return
        }
        
        isLoading = true
        error = nil
        
        authService.register(username: registerUsername, password: registerPassword, email: registerEmail) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let authResponse):
                    self?.currentUser = authResponse.user
                    self?.isAuthenticated = true
                    self?.clearRegisterForm()
                case .failure(let error):
                    switch error {
                    case .serverError(let message):
                        self?.error = message
                    default:
                        self?.error = "注册失败，请稍后重试"
                    }
                }
            }
        }
    }
    
    // 登出
    func logout() {
        authService.logout()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // 清除登录表单
    private func clearLoginForm() {
        loginUsername = ""
        loginPassword = ""
    }
    
    // 清除注册表单
    private func clearRegisterForm() {
        registerUsername = ""
        registerPassword = ""
        registerEmail = ""
        confirmPassword = ""
    }
} 