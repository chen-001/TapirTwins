import Foundation

// MARK: - 缓存管理器
class CacheManager {
    static let shared = CacheManager()
    
    // 缓存结构 - 确保能处理Encodable的数据
    private class CacheEntry<T: Encodable> {
        let data: T
        let timestamp: Date
        
        init(data: T, timestamp: Date = Date()) {
            self.data = data
            self.timestamp = timestamp
        }
        
        // 缓存永不过期
        var isExpired: Bool {
            return false // 永不过期
        }
    }
    
    // 用于写入磁盘的缓存封装结构
    private struct CacheEnvelope: Codable {
        let timestamp: Date
        let json: Data
        // 添加版本字段，以便未来格式变更时能够识别
        let version: Int = 1
    }
    
    // 内存缓存 - 使用Any类型存储各种CacheEntry
    private var memoryCache = [String: Any]()
    
    // 缓存目录
    private var cacheDirectory: URL {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let appCacheDirectory = cacheDirectory.appendingPathComponent("TapirTwinsCache", isDirectory: true)
        
        // 确保缓存目录存在
        if !fileManager.fileExists(atPath: appCacheDirectory.path) {
            try? fileManager.createDirectory(at: appCacheDirectory, withIntermediateDirectories: true)
        }
        
        return appCacheDirectory
    }
    
    // 缓存版本
    private let currentCacheVersion = 1
    
    private init() {
        // 不再在每次初始化时清除缓存
        // 而是检查当前应用版本，只在需要时执行迁移或清理
        print("缓存管理器已初始化，缓存将保持永久有效")
        
        // 预加载磁盘缓存到内存中以提高性能
        preloadCacheFromDisk()
    }
    
    // 预加载磁盘缓存到内存
    private func preloadCacheFromDisk() {
        do {
            if FileManager.default.fileExists(atPath: cacheDirectory.path) {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: cacheDirectory, 
                                                                      includingPropertiesForKeys: nil)
                if !fileURLs.isEmpty {
                    print("找到\(fileURLs.count)个磁盘缓存文件")
                    
                    // 只预加载特定重要的缓存
                    let commonCacheKeys = ["dreams_[Dream].self", "tasks_[TapirTask].self"]
                    
                    for key in commonCacheKeys {
                        let url = fileURL(for: key)
                        if fileURLs.contains(url) {
                            print("预加载重要缓存: \(key)")
                            
                            // 我们在这里不需要实际解析数据
                            // 当第一次通过getData访问时会自动加载
                        }
                    }
                }
            }
        } catch {
            print("读取缓存目录失败: \(error)")
        }
    }
    
    // 获取缓存文件URL
    private func fileURL(for key: String) -> URL {
        let fileName = key.replacingOccurrences(of: "/", with: "_")
                          .replacingOccurrences(of: ":", with: "_")
                          .replacingOccurrences(of: ".", with: "_")
        return cacheDirectory.appendingPathComponent("\(fileName).cache")
    }
    
    // 添加数据到缓存 - T必须是Encodable
    func cache<T: Encodable>(_ data: T, for key: String) {
        // 存入内存缓存
        let entry = CacheEntry(data: data)
        memoryCache[key] = entry
        
        // 存入磁盘缓存
        saveToDisk(data, for: key)
    }
    
    // 从缓存获取数据 - T必须是Decodable和Encodable
    func getData<T: Decodable & Encodable>(for key: String) -> T? {
        // 首先尝试从内存缓存获取
        if let cacheEntry = memoryCache[key] {
            // 尝试从内存缓存中直接提取数据
            if let typedEntry = cacheEntry as? CacheEntry<T> {
                print("从内存缓存获取数据: \(key)")
                return typedEntry.data
            }
        }
        
        // 从磁盘加载
        if let diskData: T = loadFromDisk(for: key) {
            // 加载成功后，更新内存缓存
            let entry = CacheEntry(data: diskData)
            memoryCache[key] = entry
            print("从磁盘缓存加载并更新内存缓存: \(key)")
            return diskData
        }
        
        return nil
    }
    
    // 清除特定缓存
    func clearCache(for key: String) {
        memoryCache.removeValue(forKey: key)
        removeFromDisk(for: key)
    }
    
    // 清除所有缓存
    func clearAllCache() {
        memoryCache.removeAll()
        
        // 删除缓存目录中的所有文件
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: cacheDirectory.path) {
                let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, 
                                                                includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    try? fileManager.removeItem(at: fileURL)
                }
                print("已清除所有磁盘缓存")
            }
        } catch {
            print("清除所有磁盘缓存失败: \(error)")
        }
    }
    
    // 将数据保存到磁盘
    private func saveToDisk<T: Encodable>(_ data: T, for key: String) {
        let fileURL = self.fileURL(for: key)
        
        do {
            // 编码数据
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(data)
            
            // 创建封装对象
            let envelope = CacheEnvelope(timestamp: Date(), json: jsonData)
            let envelopeData = try encoder.encode(envelope)
            
            // 写入文件
            try envelopeData.write(to: fileURL)
            print("已将缓存保存到磁盘: \(key)")
        } catch {
            print("保存缓存到磁盘失败: \(key) - \(error)")
        }
    }
    
    // 从磁盘加载数据
    private func loadFromDisk<T: Decodable & Encodable>(for key: String) -> T? {
        let fileURL = self.fileURL(for: key)
        let fileManager = FileManager.default
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // 文件不存在，这是正常情况，不打印错误
            return nil
        }
        
        do {
            // 读取文件内容
            let data = try Data(contentsOf: fileURL)
            
            // 解析封装对象
            let decoder = JSONDecoder()
            do {
                let envelope = try decoder.decode(CacheEnvelope.self, from: data)
                
                // 检查缓存版本
                if envelope.version != currentCacheVersion {
                    print("缓存版本不匹配，删除旧版本缓存: \(key)")
                    try? fileManager.removeItem(at: fileURL)
                    return nil
                }
                
                // 直接解析实际数据
                do {
                    let decodedData = try decoder.decode(T.self, from: envelope.json)
                    return decodedData
                } catch {
                    print("解析缓存数据失败: \(key) - \(error)")
                    // 如果无法解析为请求的类型，删除缓存
                    try? fileManager.removeItem(at: fileURL)
                    return nil
                }
            } catch {
                print("解析缓存封装失败: \(key) - \(error)")
                // 尝试直接解析文件内容作为备选方案
                do {
                    let decodedData = try decoder.decode(T.self, from: data)
                    print("直接从缓存文件解析数据成功: \(key)")
                    return decodedData
                } catch {
                    // 如果还是失败，删除可能损坏的文件
                    try? fileManager.removeItem(at: fileURL)
                    return nil
                }
            }
        } catch {
            print("读取缓存文件失败: \(key) - \(error)")
            // 如果文件读取失败，删除可能损坏的文件
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    // 从磁盘删除缓存
    private func removeFromDisk(for key: String) {
        let fileURL = self.fileURL(for: key)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

class APIService {
    static let shared = APIService()
    
    // 使用APIConfig中的配置
    private let baseURL = APIConfig.API.base
    
    private init() {}
    
    // 辅助方法：清除特定类型的缓存
    private func clearCache(for endpoint: String) {
        // 尝试清除可能的缓存键
        CacheManager.shared.clearCache(for: "\(endpoint)_[Dream].self")
        CacheManager.shared.clearCache(for: "\(endpoint)_Dream.self")
        
        // 如果是空间相关的操作，也清除空间缓存
        if endpoint.contains("spaces") {
            CacheManager.shared.clearCache(for: "spaces_[Space].self")
            CacheManager.shared.clearCache(for: "spaces_Space.self")
            
            // 提取空间ID (如果存在)
            if let spaceId = endpoint.components(separatedBy: "/").last, 
               endpoint.contains("/dreams") {
                // 清除特定空间的梦境缓存
                CacheManager.shared.clearCache(for: "spaces/\(spaceId)/dreams_[Dream].self")
            }
        }
        
        // 如果是梦境相关的操作，清除梦境缓存
        if endpoint.contains("dreams") {
            CacheManager.shared.clearCache(for: "dreams_[Dream].self")
        }
    }
    
    // 使用APIConfig中的图片URL生成方法
    static func imageURL(for filename: String) -> String {
        return APIConfig.API.imageURL(for: filename)
    }
    
    // MARK: - 通用请求方法
    
    func request<T: Decodable & Encodable>(
        endpoint: String,
        method: String,
        body: Data? = nil,
        urlParams: [String: String]? = nil,
        requiresAuth: Bool = true,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        // 为GET请求使用缓存，但如果提供了URL参数则跳过缓存（通常URL参数表示特殊请求）
        if method == "GET" && urlParams == nil {
            let cacheKey = "\(endpoint)_\(T.self)"
            
            // 尝试从缓存获取数据
            if let cachedData: T = CacheManager.shared.getData(for: cacheKey) {
                print("从缓存获取数据: \(endpoint)")
                completion(.success(cachedData))
                return
            }
        }
        
        var urlString = "\(baseURL)/\(endpoint)"
        
        // 添加URL参数
        if let params = urlParams, !params.isEmpty {
            var queryItems: [URLQueryItem] = []
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            
            // 如果URL已经包含查询参数，则附加到现有参数
            if var urlComponents = URLComponents(string: urlString) {
                var existingQueryItems = urlComponents.queryItems ?? []
                existingQueryItems.append(contentsOf: queryItems)
                urlComponents.queryItems = existingQueryItems
                
                if let updatedURL = urlComponents.url?.absoluteString {
                    urlString = updatedURL
                }
            } else {
                // 如果URLComponents创建失败，则手动添加参数
                let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
                urlString += urlString.contains("?") ? "&\(queryString)" : "?\(queryString)"
            }
        }
        
        guard let url = URL(string: urlString) else {
            print("API请求错误: 无效URL - \(urlString)")
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
                
                // 缓存GET请求的结果
                if method == "GET" {
                    let cacheKey = "\(endpoint)_\(T.self)"
                    CacheManager.shared.cache(decodedData, for: cacheKey)
                    print("数据已缓存: \(endpoint)")
                }
                
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
    
    func fetchDreams(urlParams: [String: String]? = nil, completion: @escaping (Result<[Dream], APIError>) -> Void) {
        request(endpoint: "dreams", method: "GET", urlParams: urlParams, completion: completion)
    }
    
    func fetchDream(id: String, urlParams: [String: String]? = nil, completion: @escaping (Result<Dream, APIError>) -> Void) {
        request(endpoint: "dreams/\(id)", method: "GET", urlParams: urlParams, completion: completion)
    }
    
    func createDream(dream: DreamRequest, completion: @escaping (Result<Dream, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(dream) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "dreams", method: "POST", body: body) { [weak self] (result: Result<Dream, APIError>) in
            // 清除梦境缓存
            self?.clearCache(for: "dreams")
            completion(result)
        }
    }
    
    func updateDream(id: String, dream: DreamRequest, completion: @escaping (Result<Dream, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(dream) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "dreams/\(id)", method: "PUT", body: body) { [weak self] (result: Result<Dream, APIError>) in
            // 清除梦境缓存
            self?.clearCache(for: "dreams")
            self?.clearCache(for: "dreams/\(id)")
            completion(result)
        }
    }
    
    func deleteDream(id: String, completion: @escaping (Result<EmptyResponse, APIError>) -> Void) {
        request(endpoint: "dreams/\(id)", method: "DELETE") { [weak self] (result: Result<EmptyResponse, APIError>) in
            // 清除梦境缓存
            self?.clearCache(for: "dreams")
            self?.clearCache(for: "dreams/\(id)")
            completion(result)
        }
    }
    
    // MARK: - 空间梦境API
    
    func fetchSpaceDreams(spaceId: String, urlParams: [String: String]? = nil, completion: @escaping (Result<[Dream], APIError>) -> Void) {
        request(endpoint: "spaces/\(spaceId)/dreams", method: "GET", urlParams: urlParams, completion: completion)
    }
    
    func createSpaceDream(spaceId: String, dream: DreamRequest, completion: @escaping (Result<Dream, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(dream) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "spaces/\(spaceId)/dreams", method: "POST", body: body, completion: completion)
    }
    
    // MARK: - 任务API
    
    func fetchTasks(completion: @escaping (Result<[TapirTask], APIError>) -> Void) {
        print("【API调用】: 开始请求 GET \(APIConfig.TapirTask.base) 接口")
        
        request(endpoint: "tasks", method: "GET") { (result: Result<[TapirTask], APIError>) in
            switch result {
            case .success(let tasks):
                print("【API调用】: GET \(APIConfig.TapirTask.base) 成功，返回 \(tasks.count) 个任务")
                if tasks.isEmpty {
                    print("【API调用】: 警告 - 返回的任务列表为空")
                } else {
                    print("【API调用】: 成功获取到任务列表，第一个任务ID: \(tasks[0].id), 标题: \(tasks[0].title)")
                }
                completion(.success(tasks))
            case .failure(let error):
                print("【API调用】: GET \(APIConfig.TapirTask.base) 失败，错误: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func fetchTask(id: String, completion: @escaping (Result<TapirTask, APIError>) -> Void) {
        request(endpoint: "tasks/\(id)", method: "GET", completion: completion)
    }
    
    func createTask(task: TaskRequest, completion: @escaping (Result<TapirTask, APIError>) -> Void) {
        guard let body = try? JSONEncoder().encode(task) else {
            completion(.failure(.unknown))
            return
        }
        
        request(endpoint: "tasks", method: "POST", body: body, completion: completion)
    }
    
    func updateTask(id: String, task: TaskRequest, completion: @escaping (Result<TapirTask, APIError>) -> Void) {
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
    
    func fetchTaskRecords(taskId: String, urlParams: [String: String]? = nil, completion: @escaping (Result<[TaskRecord], APIError>) -> Void) {
        request(
            endpoint: APIConfig.TapirTask.records(id: taskId).replacingOccurrences(of: "\(baseURL)/", with: ""), 
            method: "GET", 
            urlParams: urlParams,
            completion: completion
        )
    }
    
    func fetchTodayRecords(urlParams: [String: String]? = nil, completion: @escaping (Result<[TaskRecord], APIError>) -> Void) {
        request(
            endpoint: APIConfig.TapirTask.todayRecords.replacingOccurrences(of: "\(baseURL)/", with: ""), 
            method: "GET", 
            urlParams: urlParams,
            completion: completion
        )
    }
    
    func deleteTask(id: String, completion: @escaping (Result<TapirTask, APIError>) -> Void) {
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
    
    // MARK: - 任务统计相关
    
    func fetchMonthlyTaskStats(month: String, completion: @escaping (Result<MonthlyTaskStats, APIError>) -> Void) {
        request(endpoint: "tasks/stats/monthly/\(month)",
                method: "GET") { (result: Result<MonthlyTaskStats, APIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    print("成功获取\(month)月任务统计数据")
                    completion(.success(stats))
                case .failure(let error):
                    print("获取任务统计数据失败: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func triggerTaskStatsUpdate(completion: @escaping (Result<APIResponse, APIError>) -> Void) {
        request(endpoint: "tasks/stats/update",
                method: "POST") { (result: Result<APIResponse, APIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("成功触发任务统计数据更新: \(response.message)")
                    completion(.success(response))
                case .failure(let error):
                    print("触发任务统计数据更新失败: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
}
