import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
}

struct UserSettings: Codable {
    var defaultShareSpaceId: String?
    
    static let defaultsKey = "userSettings"
    
    static func load() -> UserSettings {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let settings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return settings
        }
        return UserSettings()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserSettings.defaultsKey)
        }
    }
}

struct UserSettingsRequest: Codable {
    var defaultShareSpaceId: String?
}

struct UserSettingsResponse: Codable {
    var defaultShareSpaceId: String?
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
    let email: String
} 