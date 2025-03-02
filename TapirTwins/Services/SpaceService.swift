import Foundation
import UIKit

class SpaceService {
    static let shared = SpaceService()
    
    private let apiService = APIService.shared
    
    // 使用APIConfig中的配置
    private let baseURL = APIConfig.API.base
    
    private init() {}
    
    // 获取用户的所有空间
    func fetchSpaces(completion: @escaping (Result<[Space], APIError>) -> Void) {
        apiService.request(endpoint: "spaces", method: "GET", completion: completion)
    }
    
    // 获取空间详情
    func fetchSpace(id: String, completion: @escaping (Result<Space, APIError>) -> Void) {
        apiService.request(endpoint: "spaces/\(id)", method: "GET", completion: completion)
    }
    
    // 创建新空间
    func createSpace(name: String, description: String, completion: @escaping (Result<Space, APIError>) -> Void) {
        let request = CreateSpaceRequest(name: name, description: description)
        
        guard let body = try? JSONEncoder().encode(request) else {
            print("创建空间请求编码失败")
            completion(.failure(.unknown))
            return
        }
        
        print("创建空间请求: \(String(data: body, encoding: .utf8) ?? "无法解码请求体")")
        
        apiService.request(endpoint: "spaces", method: "POST", body: body) { (result: Result<Space, APIError>) in
            switch result {
            case .success(let space):
                print("创建空间成功: \(space.name)")
                completion(.success(space))
            case .failure(let error):
                print("创建空间失败: \(error)")
                
                // 添加更详细的错误信息
                if case .decodingFailed(let decodingError) = error {
                    print("解码错误详情: \(decodingError)")
                    
                    if let typeMismatch = decodingError as? DecodingError, 
                       case .typeMismatch(let type, let context) = typeMismatch {
                        print("类型不匹配: 期望 \(type), 位置: \(context.codingPath)")
                        print("调试描述: \(context.debugDescription)")
                    } else if let keyNotFound = decodingError as? DecodingError,
                              case .keyNotFound(let key, let context) = keyNotFound {
                        print("未找到键: \(key), 位置: \(context.codingPath)")
                        print("调试描述: \(context.debugDescription)")
                    } else if let valueNotFound = decodingError as? DecodingError,
                              case .valueNotFound(let type, let context) = valueNotFound {
                        print("未找到值: 类型 \(type), 位置: \(context.codingPath)")
                        print("调试描述: \(context.debugDescription)")
                    } else if let dataCorrupted = decodingError as? DecodingError,
                              case .dataCorrupted(let context) = dataCorrupted {
                        print("数据损坏: \(context.debugDescription)")
                    }
                }
                
                completion(.failure(error))
            }
        }
    }
    
    // 通过邀请码加入空间
    func joinSpace(inviteCode: String, completion: @escaping (Result<Space, APIError>) -> Void) {
        let request = JoinSpaceRequest(inviteCode: inviteCode)
        
        guard let body = try? JSONEncoder().encode(request) else {
            print("加入空间请求编码失败")
            completion(.failure(.unknown))
            return
        }
        
        print("加入空间请求: \(String(data: body, encoding: .utf8) ?? "无法解码请求体")")
        
        apiService.request(endpoint: "spaces/join", method: "POST", body: body) { (result: Result<Space, APIError>) in
            switch result {
            case .success(let space):
                print("加入空间成功: \(space.name)")
                completion(.success(space))
            case .failure(let error):
                print("加入空间失败: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // 更新空间信息
    func updateSpace(id: String, name: String, description: String, completion: @escaping (Result<Space, APIError>) -> Void) {
        let request = CreateSpaceRequest(name: name, description: description)
        
        guard let body = try? JSONEncoder().encode(request) else {
            completion(.failure(.unknown))
            return
        }
        
        apiService.request(endpoint: "spaces/\(id)", method: "PUT", body: body, completion: completion)
    }
    
    // 删除空间
    func deleteSpace(id: String, completion: @escaping (Result<Space, APIError>) -> Void) {
        apiService.request(endpoint: "spaces/\(id)", method: "DELETE", completion: completion)
    }
    
    // 邀请成员加入空间
    func inviteMember(spaceId: String, username: String, role: MemberRole, completion: @escaping (Result<Space, APIError>) -> Void) {
        let request = InviteMemberRequest(username: username, role: role)
        
        guard let body = try? JSONEncoder().encode(request) else {
            completion(.failure(.unknown))
            return
        }
        
        apiService.request(endpoint: "spaces/\(spaceId)/members", method: "POST", body: body, completion: completion)
    }
    
    // 移除空间成员
    func removeMember(spaceId: String, userId: String, completion: @escaping (Result<Space, APIError>) -> Void) {
        apiService.request(endpoint: "spaces/\(spaceId)/members/\(userId)", method: "DELETE", completion: completion)
    }
    
    // 更新成员角色
    func updateMemberRole(spaceId: String, userId: String, role: MemberRole, completion: @escaping (Result<Space, APIError>) -> Void) {
        let request = ["role": role.rawValue]
        
        guard let body = try? JSONEncoder().encode(request) else {
            completion(.failure(.unknown))
            return
        }
        
        apiService.request(endpoint: "spaces/\(spaceId)/members/\(userId)", method: "PUT", body: body, completion: completion)
    }
    
    // 获取空间的梦境记录
    func fetchSpaceDreams(spaceId: String, completion: @escaping (Result<[Dream], APIError>) -> Void) {
        apiService.request(endpoint: "spaces/\(spaceId)/dreams", method: "GET", completion: completion)
    }
    
    // 在空间中创建梦境记录
    func createSpaceDream(spaceId: String, dream: DreamRequest, completion: @escaping (Result<Dream, APIError>) -> Void) {
        var spaceDream = dream
        spaceDream.spaceId = spaceId
        
        guard let body = try? JSONEncoder().encode(spaceDream) else {
            completion(.failure(.unknown))
            return
        }
        
        apiService.request(endpoint: "spaces/\(spaceId)/dreams", method: "POST", body: body, completion: completion)
    }
    
    // 获取空间的任务
    func fetchSpaceTasks(spaceId: String, completion: @escaping (Result<[Task], Error>) -> Void) {
        guard let token = AuthService.shared.getToken() else {
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        let urlString = APIConfig.Space.tasks(id: spaceId)
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("获取空间任务: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("获取空间任务失败: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("无效的HTTP响应")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("空间任务响应状态码: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP错误: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("没有数据返回或数据为空")
                // 如果没有数据，返回空数组而不是错误
                completion(.success([]))
                return
            }
            
            do {
                // 打印原始JSON数据以便调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("任务JSON数据: \(jsonString)")
                    
                    // 检查JSON数据是否为空数组
                    if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[]" {
                        print("服务器返回了空数组")
                        completion(.success([]))
                        return
                    }
                    
                    // 检查JSON数据是否为null
                    if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "null" {
                        print("服务器返回了null")
                        completion(.success([]))
                        return
                    }
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // 尝试解析为任务数组
                do {
                    let tasks = try decoder.decode([Task].self, from: data)
                    print("成功解析 \(tasks.count) 个任务")
                    
                    // 检查任务数据是否完整
                    for (index, task) in tasks.enumerated() {
                        if task.id.isEmpty {
                            print("警告: 第\(index)个任务ID为空")
                        }
                        if task.title.isEmpty {
                            print("警告: 第\(index)个任务标题为空")
                        }
                    }
                    
                    completion(.success(tasks))
                } catch {
                    print("解析任务数组失败，尝试解析单个任务: \(error)")
                    
                    // 尝试解析为单个任务
                    do {
                        let task = try decoder.decode(Task.self, from: data)
                        print("成功解析单个任务: \(task.id)")
                        completion(.success([task]))
                    } catch {
                        print("解析单个任务也失败: \(error)")
                        
                        // 尝试解析错误信息
                        do {
                            let errorData = try JSONDecoder().decode([String: String].self, from: data)
                            if let errorMessage = errorData["error"] {
                                print("服务器错误信息: \(errorMessage)")
                                completion(.failure(NetworkError.serverError(errorMessage)))
                            } else {
                                print("解析到错误数据但没有error字段，返回空数组")
                                completion(.success([]))
                            }
                        } catch {
                            // 如果所有解析尝试都失败，返回空数组而不是错误
                            print("所有解析尝试都失败，返回空数组")
                            completion(.success([]))
                        }
                    }
                }
            } catch {
                print("解析任务数据失败: \(error)")
                // 返回空数组而不是错误
                completion(.success([]))
            }
        }.resume()
    }
    
    // 在空间中创建任务
    func createSpaceTask(spaceId: String, task: TaskRequest, completion: @escaping (Result<Task, APIError>) -> Void) {
        // 创建任务的副本，并确保设置正确的空间ID
        var spaceTask = task
        spaceTask.spaceId = spaceId
        
        guard let body = try? JSONEncoder().encode(spaceTask) else {
            print("创建空间任务请求编码失败")
            completion(.failure(.unknown))
            return
        }
        
        print("创建空间任务请求: \(String(data: body, encoding: .utf8) ?? "无法解码请求体")")
        
        // 使用自定义的请求方法，以便更好地处理错误
        guard let token = AuthService.shared.getToken() else {
            print("创建任务失败: 未授权 - 缺少令牌")
            completion(.failure(.unauthorized))
            return
        }
        
        let urlString = "\(baseURL)/spaces/\(spaceId)/tasks"
        guard let url = URL(string: urlString) else {
            print("创建任务失败: 无效URL - \(urlString)")
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("发送创建任务请求: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("创建任务网络错误: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("创建任务无效响应")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("创建任务响应状态码: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("创建任务HTTP错误: \(httpResponse.statusCode), 响应: \(errorString)")
                } else {
                    print("创建任务HTTP错误: \(httpResponse.statusCode), 无响应数据")
                }
                completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                return
            }
            
            guard let data = data else {
                print("创建任务成功但无数据返回")
                completion(.failure(.noData))
                return
            }
            
            // 打印原始响应数据以便调试
            if let jsonString = String(data: data, encoding: .utf8) {
                print("创建任务响应数据: \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let task = try decoder.decode(Task.self, from: data)
                print("创建空间任务成功: \(task.title)")
                completion(.success(task))
            } catch {
                print("创建任务解析响应失败: \(error)")
                
                if let decodingError = error as? DecodingError {
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
                
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
    // 获取空间的任务记录
    func fetchSpaceTaskRecords(spaceId: String, completion: @escaping (Result<[TaskRecord], APIError>) -> Void) {
        guard let token = AuthService.shared.getToken() else {
            print("获取任务记录失败: 未授权 - 缺少令牌")
            completion(.failure(.unauthorized))
            return
        }
        
        let urlString = APIConfig.Space.taskRecords(id: spaceId)
        guard let url = URL(string: urlString) else {
            print("获取任务记录失败: 无效URL - \(urlString)")
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("获取空间任务记录: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("获取任务记录网络错误: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("获取任务记录无效响应")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("任务记录响应状态码: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP错误: \(httpResponse.statusCode)")
                
                // 尝试解析错误响应
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("错误响应内容: \(errorString)")
                }
                
                completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                return
            }
            
            guard let data = data else {
                print("没有数据返回")
                completion(.failure(.noData))
                return
            }
            
            // 检查数据是否为空
            if data.isEmpty {
                print("返回的数据为空，返回空数组")
                completion(.success([]))
                return
            }
            
            // 打印原始JSON数据以便调试
            if let jsonString = String(data: data, encoding: .utf8) {
                print("任务记录JSON数据: \(jsonString)")
                
                // 检查JSON数据是否为空数组
                if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "[]" {
                    print("服务器返回了空数组")
                    completion(.success([]))
                    return
                }
                
                // 检查JSON数据是否为null
                if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "null" {
                    print("服务器返回了null")
                    completion(.success([]))
                    return
                }
                
                // 检查是否包含错误信息
                if jsonString.contains("\"error\":") {
                    print("服务器返回了错误信息: \(jsonString)")
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        completion(.failure(.serverError(errorResponse.error)))
                        return
                    } catch {
                        print("解析错误信息失败: \(error)")
                    }
                }
            }
            
            // 使用更健壮的解码方式
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // 尝试解析为任务记录数组
            do {
                let records = try decoder.decode([TaskRecord].self, from: data)
                print("成功解析 \(records.count) 条任务记录")
                
                // 检查解析出的记录是否有效
                if records.isEmpty {
                    print("解析成功但没有任何记录")
                } else {
                    for (index, record) in records.enumerated() {
                        print("任务记录 \(index + 1): ID=\(record.id), 任务ID=\(record.taskId), 状态=\(record.status.rawValue)")
                    }
                }
                
                completion(.success(records))
                return
            } catch {
                print("解析任务记录数组失败: \(error)")
                
                // 详细记录解码错误
                if let decodingError = error as? DecodingError {
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
                
                // 尝试解析为单个任务记录
                do {
                    let record = try decoder.decode(TaskRecord.self, from: data)
                    print("成功解析单个任务记录: \(record.id)")
                    completion(.success([record]))
                    return
                } catch {
                    print("解析单个任务记录也失败: \(error)")
                }
                
                // 尝试解析为自定义格式
                do {
                    // 尝试解析为字典数组，然后手动构建TaskRecord对象
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        print("成功解析为字典数组，尝试手动构建TaskRecord对象")
                        
                        var records: [TaskRecord] = []
                        for (index, dict) in jsonArray.enumerated() {
                            do {
                                // 将字典重新编码为JSON数据
                                let itemData = try JSONSerialization.data(withJSONObject: dict)
                                // 尝试解码单个记录
                                let record = try decoder.decode(TaskRecord.self, from: itemData)
                                records.append(record)
                                print("成功手动解析第\(index + 1)条记录: \(record.id)")
                            } catch {
                                print("手动解析第\(index + 1)条记录失败: \(error)")
                            }
                        }
                        
                        if !records.isEmpty {
                            print("成功手动解析 \(records.count) 条记录")
                            completion(.success(records))
                            return
                        }
                    }
                } catch {
                    print("尝试手动解析失败: \(error)")
                }
                
                // 如果所有解析尝试都失败，返回解码错误
                print("所有解析尝试都失败，返回解码错误")
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
    // 获取空间的今日任务记录
    func fetchSpaceTodayRecords(spaceId: String, completion: @escaping (Result<[TaskRecord], APIError>) -> Void) {
        apiService.request(endpoint: "spaces/\(spaceId)/tasks/records/today", method: "GET", completion: completion)
    }
    
    // 审批任务记录
    func approveTaskRecord(spaceId: String, recordId: String, comment: String, completion: @escaping (Result<TaskCompleteResponse, APIError>) -> Void) {
        print("准备发送任务审批请求，空间ID: \(spaceId)，记录ID: \(recordId)，审批词: \(comment)")
        
        let request = TaskApproveRequest(comment: comment)
        
        guard let body = try? JSONEncoder().encode(request) else {
            print("任务审批请求编码失败")
            completion(.failure(.unknown))
            return
        }
        
        let urlString = APIConfig.Space.approveTask(spaceId: spaceId, recordId: recordId)
        guard let url = URL(string: urlString) else {
            print("任务审批失败: 无效URL - \(urlString)")
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(AuthService.shared.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        
        print("发送任务审批请求...")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                print("任务审批网络错误: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("任务审批无效响应")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("任务审批响应状态码: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("任务审批响应数据: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    print("任务审批失败: 未授权 - 状态码 401")
                    completion(.failure(.unauthorized))
                    return
                }
                
                if let data = data {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("任务审批失败: 服务器错误 - \(errorResponse.error)")
                        completion(.failure(.serverError(errorResponse.error)))
                    } else if let dataString = String(data: data, encoding: .utf8) {
                        print("任务审批失败: 服务器错误 - 状态码 \(httpResponse.statusCode), 响应: \(dataString)")
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    } else {
                        print("任务审批失败: 服务器错误 - 状态码 \(httpResponse.statusCode)")
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    }
                } else {
                    print("任务审批失败: 服务器错误 - 状态码 \(httpResponse.statusCode)")
                    completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                print("任务审批失败: 无数据")
                completion(.failure(.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(TaskCompleteResponse.self, from: data)
                print("任务审批成功: \(response.message)")
                completion(.success(response))
            } catch {
                print("任务审批失败: 解析响应数据失败 - \(error)")
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
    // 拒绝任务记录
    func rejectTaskRecord(spaceId: String, recordId: String, reason: String, completion: @escaping (Result<TaskCompleteResponse, APIError>) -> Void) {
        let request = TaskRejectRequest(reason: reason)
        
        guard let body = try? JSONEncoder().encode(request) else {
            completion(.failure(.unknown))
            return
        }
        
        let urlString = APIConfig.Space.rejectTask(spaceId: spaceId, recordId: recordId)
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(AuthService.shared.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        
        print("发送任务拒绝请求...")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                print("任务拒绝网络错误: \(error.localizedDescription)")
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("任务拒绝无效响应")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("任务拒绝响应状态码: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("任务拒绝响应数据: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    print("任务拒绝失败: 未授权 - 状态码 401")
                    completion(.failure(.unauthorized))
                    return
                }
                
                if let data = data {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("任务拒绝失败: 服务器错误 - \(errorResponse.error)")
                        completion(.failure(.serverError(errorResponse.error)))
                    } else if let dataString = String(data: data, encoding: .utf8) {
                        print("任务拒绝失败: 服务器错误 - 状态码 \(httpResponse.statusCode), 响应: \(dataString)")
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    } else {
                        print("任务拒绝失败: 服务器错误 - 状态码 \(httpResponse.statusCode)")
                        completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                    }
                } else {
                    print("任务拒绝失败: 服务器错误 - 状态码 \(httpResponse.statusCode)")
                    completion(.failure(.serverError("HTTP状态码: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                print("任务拒绝失败: 无数据")
                completion(.failure(.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(TaskCompleteResponse.self, from: data)
                print("任务拒绝成功: \(response.message)")
                completion(.success(response))
            } catch {
                print("任务拒绝失败: 解析响应数据失败 - \(error)")
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }
    
    // 提交任务完成记录
    func submitTask(spaceId: String, taskId: String, images: [UIImage], completion: @escaping (Result<TaskCompleteResponse, APIError>) -> Void) {
        // 将UIImage转换为base64字符串
        var base64Images: [String] = []
        
        for image in images {
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                let base64String = imageData.base64EncodedString()
                base64Images.append("data:image/jpeg;base64,\(base64String)")
            }
        }
        
        // 如果没有成功转换任何图片，则返回错误
        if base64Images.isEmpty && !images.isEmpty {
            completion(.failure(.unknown))
            return
        }
        
        // 创建请求体
        let taskCompleteRequest = TaskCompleteRequest(images: base64Images)
        
        guard let body = try? JSONEncoder().encode(taskCompleteRequest) else {
            completion(.failure(.unknown))
            return
        }
        
        // 发送请求到后端API
        apiService.request(endpoint: "tasks/\(taskId)/complete", method: "POST", body: body, completion: completion)
    }
    
    // 获取任务历史记录
    func fetchTaskHistory(spaceId: String, taskId: String, completion: @escaping (Result<[HistoryRecord], APIError>) -> Void) {
        print("准备获取任务历史记录，空间ID: \(spaceId)，任务ID: \(taskId)")
        
        apiService.request(endpoint: "spaces/\(spaceId)/tasks/\(taskId)/history", method: "GET", completion: completion)
    }
}