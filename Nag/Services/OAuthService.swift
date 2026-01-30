import Foundation
import AppKit

class OAuthService {
    // Public Client ID (safe to expose)
    private let clientID = "Ov23licG1RL6kHbffnWN"
    
    // Device Flow: Step 1 - Request device and user codes
    func startDeviceFlow(completion: @escaping (Result<(deviceCode: String, userCode: String, verificationUri: String), Error>) -> Void) {
        guard let url = URL(string: "https://github.com/login/device/code") else {
            completion(.failure(NSError(domain: "OAuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientID,
            "scope": "read:user,repo"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OAuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let deviceCode = json["device_code"] as? String,
                   let userCode = json["user_code"] as? String,
                   let verificationUri = json["verification_uri"] as? String {
                    completion(.success((deviceCode, userCode, verificationUri)))
                } else {
                    completion(.failure(NSError(domain: "OAuthService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Device Flow: Step 2 - Poll for access token
    // Yeah polling is not gambiarra here. According to https://datatracker.ietf.org/doc/html/rfc8628
    func pollForToken(deviceCode: String, interval: Int = 5, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://github.com/login/oauth/access_token") else {
            completion(.failure(NSError(domain: "OAuthService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientID,
            "device_code": deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OAuthService", code: 5, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let accessToken = json["access_token"] as? String {
                        // Success!
                        completion(.success(accessToken))
                    } else if let error = json["error"] as? String {
                        if error == "authorization_pending" {
                            // User hasn't authorized yet, continue polling
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(interval)) {
                                self.pollForToken(deviceCode: deviceCode, interval: interval, completion: completion)
                            }
                        } else if error == "slow_down" {
                            // Polling too fast, increase interval
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(interval + 5)) {
                                self.pollForToken(deviceCode: deviceCode, interval: interval + 5, completion: completion)
                            }
                        } else {
                            // Other error (expired_token, access_denied, etc.)
                            completion(.failure(NSError(domain: "OAuthService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Authorization failed: \(error)"])))
                        }
                    } else {
                        completion(.failure(NSError(domain: "OAuthService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                    }
                } else {
                    completion(.failure(NSError(domain: "OAuthService", code: 8, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
