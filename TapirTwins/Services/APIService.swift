import Foundation

class APIService {
    static let shared = APIService()
    
    // 使用APIConfig中的配置
    private let baseURL = APIConfig.API.base
    
    private init() {}
    
    // 使用APIConfig中的图片URL生成方法
    static func imageURL(for filename: String) -> String {
        return APIConfig.API.imageURL(for: filename)
    }
    
    // MARK: - 通用请求方法
    
    func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data? = nil,
        requiresAuth: Bool = true,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            print("API请求错误: 无效URL - \(baseURL)/\(endpoint)")
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // 添加认证令牌
        if requiresAuth {
            if let token = AuthService.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                print("API请求错误: 未授权 - 缺少令牌")
                completion(.failure(.unauthorized))
                return
            }
        }
        
        print("API请求: \(method) \(url.absoluteString)")
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("请求体: \(bodyString)")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API请求错误: 请求失败 - \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("API请求错误: 无效响应")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("API响应: 状态码 \(httpResponse.statusCode)")
            
            // 检查HTTP状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    print("API请求错误: 未授权 - 状态码 401")
                    completion(.failure(.unauthorized))
                    return
                }
                
                if let data = data {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("API请求错误: 服务器错误 - \(errorResponse.error)")
                        completion(.failure(.serverError(errorResponse.error)))
                    } else if let dataString = String(data: data, encoding: .utf8) {
                        print("API请求错误: 服务器错误 - 状态码 \(httpResponse.statusCode), 响应: \(dataString)")
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    } else {
                        print("API请求错误: 服务器错误 - 状态码 \(httpResponse.statusCode)")
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    }
                } else {
                    print("API请求错误: 服务器错误 - 状态码 \(httpResponse.statusCode)")
                    completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                print("API请求错误: 无数据")
                completion(.failure(.unknown))
                return
            }
            
            if let dataString = String(data: data, encoding: .utf8) {
                print("API响应数据: \(dataString)")
            }
            
            print("开始解析API响应数据...")
            if let dataString = String(data: data, encoding: .utf8) {
                print("响应数据: \(dataString)")
            }
            
            let decoder = JSONDecoder()
            do {
                let decodedData = try decoder.decode(T.self, from: data)
                print("API请求成功: 数据解析成功")
                completion(.success(decodedData))
            } catch let decodingError {
                print("API请求错误: 数据解析失败 - \(decodingError)")
                print("错误详情: \(decodingError.localizedDescription)")
                
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("解码错误: 找不到键 \(key.stringValue), 路径: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("解码错误: 找不到值, 类型: \(type), 路径: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("解码错误: 类型不匹配, 类型: \(type), 路径: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("解码错误: 数据损坏, 路径: \(context.codingPath), 描述: \(context.debugDescription)")
                    @unknown default:
                        print("解码错误: 未知解码错误")
                    }
                }
                
                if let dataString = String(data: data, encoding: .utf8) {
                    print("无法解析的数据: \(dataString)")
                }
                completion(.failure(.decodingFailed(decodingError)))
            }
        }.resume()
    }
    
    // MARK: - 梦境API
    
    func fetchDreams(completion: @escaping (Result<[Dream], APIError>) -> Void) {
        request(endpoint: "dreams", method: "GET", completion: completion)
    }
    
    func fetchDream(id: String, completion: @escaping (Result<Dream, APIError>) -> Void) {
        request(endpoint: "dreams/\(id)", method: "GET", completion: completion)
    }
    
    func createDream(dream: DreamRequest, completion: @escaping (Result<Dream, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(dream) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "dreams", method: "POST", body: body, completion: completion)
    }
    
    func updateDream(id: String, dream: DreamRequest, completion: @escaping (Result<Dream, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(dream) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "dreams/\(id)", method: "PUT", body: body, completion: completion)
    }
    
    func deleteDream(id: String, completion: @escaping (Result<Dream, APIError>) -> Void) {
        request(endpoint: "dreams/\(id)", method: "DELETE", completion: completion)
    }
    
    // MARK: - 空间梦境API
    
    func fetchSpaceDreams(spaceId: String, completion: @escaping (Result<[Dream], APIError>) -> Void) {
        request(endpoint: "spaces/\(spaceId)/dreams", method: "GET", completion: completion)
    }
    
    func createSpaceDream(spaceId: String, dream: DreamRequest, completion: @escaping (Result<Dream, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(dream) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "spaces/\(spaceId)/dreams", method: "POST", body: body, completion: completion)
    }
    
    // MARK: - 任务API
    
    func fetchTasks(completion: @escaping (Result<[Task], APIError>) -> Void) {
        print("【API调用】: 开始请求 GET /tasks 接口")
        
        request(endpoint: "tasks", method: "GET") { (result: Result<[Task], APIError>) in
            switch result {
            case .success(let tasks):
                print("【API调用】: GET /tasks 成功，返回 \(tasks.count) 个任务")
                if tasks.isEmpty {
                    print("【API调用】: 警告 - 返回的任务列表为空")
                } else {
                    print("【API调用】: 成功获取到任务列表，第一个任务ID: \(tasks[0].id), 标题: \(tasks[0].title)")
                }
                completion(.success(tasks))
            case .failure(let error):
                print("【API调用】: GET /tasks 失败，错误: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func fetchTask(id: String, completion: @escaping (Result<Task, APIError>) -> Void) {
        request(endpoint: "tasks/\(id)", method: "GET", completion: completion)
    }
    
    func createTask(task: TaskRequest, completion: @escaping (Result<Task, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(task) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "tasks", method: "POST", body: body, completion: completion)
    }
    
    func updateTask(id: String, task: TaskRequest, completion: @escaping (Result<Task, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(task) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "tasks/\(id)", method: "PUT", body: body, completion: completion)
    }
    
    func completeTask(id: String, images: [String], completion: @escaping (Result<TaskCompleteResponse, APIError>) -> Void) {
        let taskCompleteRequest = TaskCompleteRequest(images: images)
        
        guard let body = try? JSONEncoder().encode(taskCompleteRequest) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "tasks/\(id)/complete", method: "POST", body: body, completion: completion)
    }
    
    func fetchTaskRecords(taskId: String, completion: @escaping (Result<[TaskRecord], APIError>) -> Void) {
        request(endpoint: "tasks/\(taskId)/records", method: "GET", completion: completion)
    }
    
    func fetchTodayRecords(completion: @escaping (Result<[TaskRecord], APIError>) -> Void) {
        request(endpoint: "tasks/records/today", method: "GET", completion: completion)
    }
    
    func deleteTask(id: String, completion: @escaping (Result<Task, APIError>) -> Void) {
        request(endpoint: "tasks/\(id)", method: "DELETE", completion: completion)
    }
    
    // MARK: - 用户设置API
    
    func fetchUserSettings(completion: @escaping (Result<UserSettingsResponse, APIError>) -> Void) {
        request(endpoint: "user/settings", method: "GET", completion: completion)
    }
    
    func updateUserSettings(settings: UserSettingsRequest, completion: @escaping (Result<UserSettingsResponse, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(settings) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "user/settings", method: "PUT", body: body, completion: completion)
    }
}
