import Foundation

/// API配置类，用于集中管理所有API相关的URL配置
struct APIConfig {
    // 默认基础URL
    static let defaultBaseURL = "http://103.218.240.138:8081/api"
    
    // 用于存储自定义API地址的UserDefaults键
    private static let customAPIURLKey = "customAPIURL"
    
    // 基础URL - 优先使用用户自定义的URL，如果没有则使用默认URL
    static var baseURL: String {
        get {
            return UserDefaults.standard.string(forKey: customAPIURLKey) ?? defaultBaseURL
        }
        set {
            UserDefaults.standard.set(newValue, forKey: customAPIURLKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    // 重置为默认URL
    static func resetToDefaultURL() {
        UserDefaults.standard.removeObject(forKey: customAPIURLKey)
        UserDefaults.standard.synchronize()
    }
    
    // API服务相关URL
    struct API {
        static var base: String {
            return baseURL
        }
        
        static var images: String {
            return "\(baseURL)/images"
        }
        
        // 生成图片URL的方法
        static func imageURL(for filename: String) -> String {
            // 添加调试输出
            print("生成图片URL，原始文件名: \(filename)")
            
            // 检查filename是否已经是完整URL
            if filename.lowercased().hasPrefix("http") {
                print("文件名已经是完整URL: \(filename)")
                return filename
            }
            
            // 如果filename已经包含/images/路径，则直接拼接基础URL的主机部分
            if filename.hasPrefix("/images/") {
                // 从baseURL中提取主机部分
                if let url = URL(string: baseURL), let host = url.host {
                    let scheme = url.scheme ?? "http"
                    let port = url.port != nil ? ":\(url.port!)" : ""
                    let baseHost = "\(scheme)://\(host)\(port)"
                    let result = "\(baseHost)\(filename)"
                    print("文件名包含/images/路径，拼接主机结果: \(result)")
                    return result
                } else {
                    let result = "\(baseURL)\(filename)"
                    print("文件名包含/images/路径，拼接结果: \(result)")
                    return result
                }
            }
            
            // 标准化文件名（去除可能的前导斜杠）
            let normalizedFilename = filename.hasPrefix("/") ? String(filename.dropFirst()) : filename
            
            // 返回完整的图片URL
            let result = "\(images)/\(normalizedFilename)"
            print("生成的完整图片URL: \(result)")
            
            // 检查URL是否可以被正确解析
            if URL(string: result) == nil {
                print("警告: 生成的URL无法被解析，尝试进行URL编码")
                if let encodedFilename = normalizedFilename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                   let encodedURL = URL(string: "\(images)/\(encodedFilename)") {
                    print("URL编码后的结果: \(encodedURL.absoluteString)")
                    return encodedURL.absoluteString
                }
            }
            
            return result
        }
    }
    
    // 认证服务相关URL
    struct Auth {
        static var base: String {
            return "\(baseURL)/auth"
        }
        
        static var login: String {
            return "\(base)/login"
        }
        
        static var register: String {
            return "\(base)/register"
        }
    }
    
    // 空间服务相关URL
    struct Space {
        static var base: String {
            return "\(baseURL)/spaces"
        }
        
        static func detail(id: String) -> String {
            return "\(base)/\(id)"
        }
        
        static func members(id: String) -> String {
            return "\(detail(id: id))/members"
        }
        
        static func member(spaceId: String, userId: String) -> String {
            return "\(members(id: spaceId))/\(userId)"
        }
        
        static func dreams(id: String) -> String {
            return "\(detail(id: id))/dreams"
        }
        
        static func tasks(id: String) -> String {
            return "\(detail(id: id))/tasks"
        }
        
        static func taskRecords(id: String) -> String {
            return "\(tasks(id: id))/records"
        }
        
        static func todayRecords(id: String) -> String {
            return "\(taskRecords(id: id))/today"
        }
        
        static func taskRecord(spaceId: String, recordId: String) -> String {
            return "\(taskRecords(id: spaceId))/\(recordId)"
        }
        
        static func approveTask(spaceId: String, recordId: String) -> String {
            return "\(taskRecord(spaceId: spaceId, recordId: recordId))/approve"
        }
        
        static func rejectTask(spaceId: String, recordId: String) -> String {
            return "\(taskRecord(spaceId: spaceId, recordId: recordId))/reject"
        }
        
        static var join: String {
            return "\(base)/join"
        }
    }
    
    // 梦境服务相关URL
    struct Dream {
        static var base: String {
            return "\(baseURL)/dreams"
        }
        
        static func detail(id: String) -> String {
            return "\(base)/\(id)"
        }
    }
    
    // 任务服务相关URL
    struct TapirTask {
        static var base: String {
            return "\(baseURL)/tasks"
        }
        
        static func detail(id: String) -> String {
            return "\(base)/\(id)"
        }
        
        static func records(id: String) -> String {
            return "\(detail(id: id))/records"
        }
        
        static var todayRecords: String {
            return "\(base)/records/today"
        }
    }
    
    // 用户服务相关URL
    struct User {
        static var base: String {
            return "\(baseURL)/user"
        }
        
        static var profile: String {
            return "\(base)/profile"
        }
        
        static var settings: String {
            return "\(base)/settings"
        }
    }
}
