import Foundation

class Config {
    private let defaults = UserDefaults.standard
    private let tokenKey = "github_token"
    private let usernameKey = "github_username"
    private let reposKey = "monitored_repositories"
    
    func hasToken() -> Bool {
        return getToken() != nil
    }
    
    func getToken() -> String? {
        return defaults.string(forKey: tokenKey)
    }
    
    func saveToken(_ token: String) {
        defaults.set(token, forKey: tokenKey)
    }
    
    func deleteToken() {
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: reposKey)
    }
    
    func getUsername() -> String? {
        return defaults.string(forKey: usernameKey)
    }
    
    func saveUsername(_ username: String) {
        defaults.set(username, forKey: usernameKey)
    }
    
    func getRepos() -> [String] {
        return defaults.stringArray(forKey: reposKey) ?? []
    }
    
    func saveRepos(_ repos: [String]) {
        let filtered = repos.filter { !$0.isEmpty }
        defaults.set(filtered, forKey: reposKey)
    }
}
