//
//  GoogleAuthService.swift
//  AICustomerResverSystem
//

import Foundation
import SwiftUI
import AuthenticationServices

@Observable
@MainActor
class GoogleAuthService {
    static let shared = GoogleAuthService()
    
    // We allow user configuration of Google Client ID, with a standard default placeholder.
    // iOS developers create an iOS OAuth Client ID in Google Cloud Console.
    var clientID: String {
        UserDefaults.standard.string(forKey: "google_client_id") ?? "1043586711904-placeholder.apps.googleusercontent.com"
    }
    
    var activeEmail: String {
        get { UserDefaults.standard.string(forKey: "google_active_email") ?? "" }
        set { 
            UserDefaults.standard.set(newValue, forKey: "google_active_email")
            refreshActiveState()
        }
    }
    
    var isAuthorized: Bool = false
    var activeDisplayName: String = ""
    var registeredAccounts: [String] = []
    
    private let presentationProvider = PresentationContextProvider()
    
    private init() {
        refreshActiveState()
    }
    
    func setClientID(_ newID: String) {
        let cleanID = newID.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(cleanID, forKey: "google_client_id")
    }
    
    func refreshActiveState() {
        registeredAccounts = KeychainHelper.shared.getRegisteredAccounts()
        if !activeEmail.isEmpty, let creds = KeychainHelper.shared.readCredentials(email: activeEmail) {
            isAuthorized = true
            activeDisplayName = creds.displayName
        } else {
            isAuthorized = false
            activeDisplayName = ""
            // Fall back to first available if active is empty but accounts exist
            if let firstAccount = registeredAccounts.first {
                activeEmail = firstAccount
            }
        }
    }
    
    // MARK: - Sign In / Authentication
    
    func signIn() async throws {
        var cleanClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Strip protocols if mistakenly pasted
        if cleanClientID.hasPrefix("http://") {
            cleanClientID = cleanClientID.replacingOccurrences(of: "http://", with: "")
        }
        if cleanClientID.hasPrefix("https://") {
            cleanClientID = cleanClientID.replacingOccurrences(of: "https://", with: "")
        }
        
        guard !cleanClientID.isEmpty && cleanClientID.contains(".apps.googleusercontent.com") else {
            throw NSError(domain: "GoogleAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "請先在設定中輸入有效的 Google iOS 密鑰 (Client ID)。"])
        }
        
        // Custom URL scheme is the reverse DNS of the client ID
        let schemeParts = cleanClientID.components(separatedBy: ".")
        var reverseScheme = schemeParts.reversed().joined(separator: ".")
        
        // Strip out any accidental colons or slashes from the scheme
        reverseScheme = reverseScheme
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct redirect URI conforming to iOS standard
        let redirectURI = "\(reverseScheme):/oauth3redirect"
        
        var urlComponents = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: cleanClientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email"),
            URLQueryItem(name: "prompt", value: "select_account")
        ]
        
        guard let authURL = urlComponents.url else {
            throw NSError(domain: "GoogleAuthService", code: 500, userInfo: [NSLocalizedDescriptionKey: "無法產生驗證網址"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: reverseScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: NSError(domain: "GoogleAuthService", code: 500, userInfo: [NSLocalizedDescriptionKey: "無法取得 Google 授權碼。"]))
                    return
                }
                
                // Perform token exchange asynchronously
                Task {
                    do {
                        try await self.exchangeAuthorizationCode(code, redirectURI: redirectURI)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = presentationProvider
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    private func exchangeAuthorizationCode(_ code: String, redirectURI: String) async throws {
        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "code": code,
            "client_id": clientID.trimmingCharacters(in: .whitespacesAndNewlines),
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]
        
        let requestBody = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = requestBody.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "未知錯誤"
            print("[GoogleAuthService] Token Exchange Failed: \(errorText)")
            throw NSError(domain: "GoogleAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "交換 Token 失敗：\(errorText)"])
        }
        
        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        
        // Fetch User Info
        let userInfo = try await fetchUserInfo(accessToken: tokenResponse.access_token)
        
        let credentials = GoogleCredentials(
            email: userInfo.email,
            displayName: userInfo.name,
            accessToken: tokenResponse.access_token,
            // Refresh token is only sent on first auth, fallback if nil
            refreshToken: tokenResponse.refresh_token ?? "",
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        )
        
        // Save to Keychain
        let readExisting = KeychainHelper.shared.readCredentials(email: userInfo.email)
        let refreshTokenToSave = credentials.refreshToken.isEmpty ? (readExisting?.refreshToken ?? "") : credentials.refreshToken
        
        let finalCredentials = GoogleCredentials(
            email: credentials.email,
            displayName: credentials.displayName,
            accessToken: credentials.accessToken,
            refreshToken: refreshTokenToSave,
            expiresAt: credentials.expiresAt
        )
        
        _ = KeychainHelper.shared.saveCredentials(finalCredentials)
        self.activeEmail = finalCredentials.email
        print("[GoogleAuthService] Signed in successfully: \(finalCredentials.email)")
    }
    
    // MARK: - Token Refreshing
    
    func getValidAccessToken(email: String) async throws -> String {
        guard let credentials = KeychainHelper.shared.readCredentials(email: email) else {
            throw NSError(domain: "GoogleAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "該帳號未在金鑰庫登錄。"])
        }
        
        if !credentials.isExpired {
            return credentials.accessToken
        }
        
        // Token expired, refresh it
        print("[GoogleAuthService] Access token expired for \(email). Refreshing...")
        return try await refreshAccessToken(email: email)
    }
    
    func refreshAccessToken(email: String) async throws -> String {
        guard let credentials = KeychainHelper.shared.readCredentials(email: email) else {
            throw NSError(domain: "GoogleAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "無效的 Google 帳號憑證。"])
        }
        
        guard !credentials.refreshToken.isEmpty else {
            throw NSError(domain: "GoogleAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "授權過期，請重新登入 Google 帳號。"])
        }
        
        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_id": clientID.trimmingCharacters(in: .whitespacesAndNewlines),
            "refresh_token": credentials.refreshToken,
            "grant_type": "refresh_token"
        ]
        
        let requestBody = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = requestBody.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "未知錯誤"
            print("[GoogleAuthService] Token Refresh Failed: \(errorText)")
            // If invalid_grant, credentials are revoked, delete them
            if errorText.contains("invalid_grant") {
                _ = KeychainHelper.shared.deleteCredentials(email: email)
                if self.activeEmail == email { self.activeEmail = "" }
            }
            throw NSError(domain: "GoogleAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "自動刷新憑證失敗，請重試登入。"])
        }
        
        let refreshResponse = try JSONDecoder().decode(GoogleTokenRefreshResponse.self, from: data)
        
        var updatedCredentials = credentials
        updatedCredentials.accessToken = refreshResponse.access_token
        updatedCredentials.expiresAt = Date().addingTimeInterval(TimeInterval(refreshResponse.expires_in))
        
        _ = KeychainHelper.shared.saveCredentials(updatedCredentials)
        
        print("[GoogleAuthService] Access token refreshed successfully for \(email).")
        return refreshResponse.access_token
    }
    
    func signOut(email: String) {
        _ = KeychainHelper.shared.deleteCredentials(email: email)
        if activeEmail == email {
            activeEmail = ""
        } else {
            refreshActiveState()
        }
    }
    
    // MARK: - Private API Helpers
    
    private func fetchUserInfo(accessToken: String) async throws -> GoogleUserInfo {
        let url = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "GoogleAuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "無法取得 Google 個人帳戶資訊"])
        }
        
        return try JSONDecoder().decode(GoogleUserInfo.self, from: data)
    }
}

// MARK: - Codable Responses

private struct GoogleTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String
    let token_type: String
}

private struct GoogleTokenRefreshResponse: Codable {
    let access_token: String
    let expires_in: Int
    let scope: String
    let token_type: String
}

private struct GoogleUserInfo: Codable {
    let sub: String
    let name: String
    let email: String
    let email_verified: Bool
    let picture: String?
}

// MARK: - Presenting context helper
private class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("No window scene available")
        }
        return windowScene.windows.first(where: { $0.isKeyWindow }) ?? UIWindow(windowScene: windowScene)
    }
}
