import Foundation

struct PullRequest: Codable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let repository: String
    let author: String
    let url: String
    let updatedAt: String
}

// Nonisolated Codable conformance
extension PullRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case repository
        case author
        case url
        case updatedAt = "updated_at"
    }
}

// GitHub API Response Models
struct GitHubSearchResponse: Sendable {
    let items: [GitHubIssue]
}

// Nonisolated Codable conformance
extension GitHubSearchResponse: Codable {}

struct GitHubIssue: Sendable {
    let id: Int
    let number: Int
    let title: String
    let htmlUrl: String
    let updatedAt: String
    let user: GitHubUser
    let repositoryUrl: String
}

// Nonisolated Codable conformance
extension GitHubIssue: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case htmlUrl = "html_url"
        case updatedAt = "updated_at"
        case user
        case repositoryUrl = "repository_url"
    }
}

struct GitHubUser: Sendable {
    let login: String
}

// Nonisolated Codable conformance
extension GitHubUser: Codable {}

struct GitHubUserResponse: Sendable {
    let login: String
}
// Nonisolated Codable conformance
extension GitHubUserResponse: Codable {}

