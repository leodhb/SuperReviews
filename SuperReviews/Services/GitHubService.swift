import Foundation

class GitHubService {
    private let config: Config
    
    init(config: Config) {
        self.config = config
    }
    
    func fetchUserInfo(completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = config.getToken() else {
            completion(.failure(NSError(domain: "GitHubService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No token found"])))
            return
        }
        
        validateToken(token, completion: completion)
    }
    
    func validateToken(_ token: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.github.com/user") else {
            completion(.failure(NSError(domain: "GitHubService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("SuperReviews/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GitHubService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "GitHubService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid token or API error"])))
                return
            }
            
            do {
                let userResponse = try JSONDecoder().decode(GitHubUserResponse.self, from: data)
                completion(.success(userResponse.login))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchPRs(completion: @escaping (Result<[PullRequest], Error>) -> Void) {
        guard let token = config.getToken() else {
            completion(.failure(NSError(domain: "GitHubService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No token found"])))
            return
        }
        
        let repos = config.getRepos()
        
        // Build query prefix for repo filtering
        let prefix = repos.isEmpty ? "" : repos.map { "repo:\($0)" }.joined(separator: " ") + " "
        
        // Use only the most reliable query format
        let query = "\(prefix)is:pr is:open review-requested:@me"
        
        fetchWithQuery(query, token: token, completion: completion)
    }
    
    private func fetchWithQuery(_ query: String, token: String, completion: @escaping (Result<[PullRequest], Error>) -> Void) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://api.github.com/search/issues?q=\(encodedQuery)") else {
            completion(.failure(NSError(domain: "GitHubService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        print("🔍 Trying query: \(query)")
        
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("SuperReviews/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GitHubService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "GitHubService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            print("📡 Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ API error: \(errorString)")
                completion(.failure(NSError(domain: "GitHubService", code: 5, userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])))
                return
            }
            
            do {
                let searchResponse = try JSONDecoder().decode(GitHubSearchResponse.self, from: data)
                print("📊 Found \(searchResponse.items.count) items")
                
                let prs = searchResponse.items.map { item -> PullRequest in
                    // Extract repo name from repository_url
                    let repoName = item.repositoryUrl.components(separatedBy: "/repos/").last ?? "unknown"
                    
                    return PullRequest(
                        id: item.id,
                        number: item.number,
                        title: item.title,
                        repository: repoName,
                        author: item.user.login,
                        url: item.htmlUrl,
                        updatedAt: item.updatedAt
                    )
                }
                
                completion(.success(prs))
            } catch {
                print("❌ Parse error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
