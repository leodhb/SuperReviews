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
        request.setValue("Nag/1.0", forHTTPHeaderField: "User-Agent")
        
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
        
        let monitoredRepos = config.getRepos()
        
        // If no repos specified, monitor all accessible repositories
        if monitoredRepos.isEmpty {
            let query = "is:pr is:open review-requested:@me"
            fetchWithQuery(query, token: token, completion: completion)
            return
        }
        
        // Fetch PRs only from monitored repos
        let dispatchGroup = DispatchGroup()
        var allPRs: [PullRequest] = []
        var errors: [Error] = []
        let syncQueue = DispatchQueue(label: "com.nag.prfetch")
        
        for repo in monitoredRepos {
            dispatchGroup.enter()
            let query = "repo:\(repo) is:pr is:open review-requested:@me"
            
            fetchWithQuery(query, token: token) { result in
                defer { dispatchGroup.leave() }
                
                switch result {
                case .success(let prs):
                    syncQueue.async {
                        allPRs.append(contentsOf: prs)
                    }
                case .failure(let error):
                    syncQueue.async {
                        errors.append(error)
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if allPRs.isEmpty && !errors.isEmpty {
                // If we got no PRs and had errors, report the first error
                completion(.failure(errors.first!))
            } else {
                // Remove duplicates based on PR ID
                let uniquePRs = Array(Dictionary(grouping: allPRs, by: { $0.id })
                    .compactMap { $0.value.first })
                    .sorted { $0.updatedAt > $1.updatedAt }
                
                completion(.success(uniquePRs))
            }
        }
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
        request.setValue("Nag/1.0", forHTTPHeaderField: "User-Agent")
        
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
