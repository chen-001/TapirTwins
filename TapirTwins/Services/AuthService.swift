import Foundation

// 定义错误响应结构体
struct AuthErrorResponse: Codable {
    let error: String
}

class AuthService {
    static let shared = AuthService()
    
    private let baseURL: String
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "authToken"
    private let userKey = "currentUser"
    
    private init() {
        // 使用APIConfig中的认证服务基础URL
        self.baseURL = APIConfig.Auth.base
    }
    
    // 保存认证信息
    func saveAuthInfo(token: String, user: User) {
        userDefaults.set(token, forKey: tokenKey)
        
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
    
    // 获取当前用户
    func getCurrentUser() -> User? {
        guard let userData = userDefaults.data(forKey: userKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(User.self, from: userData)
    }
    
    // 获取认证令牌
    func getToken() -> String? {
        return userDefaults.string(forKey: tokenKey)
    }
    
    // 检查是否已登录
    var isLoggedIn: Bool {
        return getToken() != nil
    }
    
    // 登出
    func logout() {
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: userKey)
    }
    
    // 登录
    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let loginRequest = LoginRequest(username: username, password: password)
        
        guard let url = URL(string: APIConfig.Auth.login),
              let body = try? JSONEncoder().encode(loginRequest) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // 检查HTTP状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data {
                    if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                        completion(.failure(.serverError(errorResponse.error)))
                    } else {
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    }
                } else {
                    completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(.unknown))
                return
            }
            
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                // 保存认证信息
                self.saveAuthInfo(token: authResponse.token, user: authResponse.user)
                completion(.success(authResponse))
            } catch let decodingError {
                completion(.failure(.decodingFailed(decodingError)))
            }
        }.resume()
    }
    
    // 注册
    func register(username: String, password: String, email: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let registerRequest = RegisterRequest(username: username, password: password, email: email)
        
        guard let url = URL(string: APIConfig.Auth.register),
              let body = try? JSONEncoder().encode(registerRequest) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // 检查HTTP状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data {
                    if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                        completion(.failure(.serverError(errorResponse.error)))
                    } else {
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    }
                } else {
                    completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(.unknown))
                return
            }
            
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                // 保存认证信息
                self.saveAuthInfo(token: authResponse.token, user: authResponse.user)
                completion(.success(authResponse))
            } catch let decodingError {
                completion(.failure(.decodingFailed(decodingError)))
            }
        }.resume()
    }
}