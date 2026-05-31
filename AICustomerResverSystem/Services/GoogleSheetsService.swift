//
//  GoogleSheetsService.swift
//  AICustomerResverSystem
//

import Foundation

struct GoogleDriveFile: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let mimeType: String
}

class GoogleSheetsService {
    static let shared = GoogleSheetsService()
    private init() {}
    
    private var authService: GoogleAuthService { GoogleAuthService.shared }
    
    // MARK: - Private API Request Helper
    
    private func performRequest(url: URL, method: String, body: Data? = nil, headers: [String: String] = [:]) async throws -> Data {
        let activeEmail = await MainActor.run { authService.activeEmail }
        guard !activeEmail.isEmpty else {
            throw NSError(domain: "GoogleSheetsService", code: 401, userInfo: [NSLocalizedDescriptionKey: "尚未登入 Google 帳戶"])
        }
        
        let token = try await authService.getValidAccessToken(email: activeEmail)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GoogleSheetsService", code: 500, userInfo: [NSLocalizedDescriptionKey: "伺服器無回應"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "未知伺服器錯誤"
            print("[GoogleSheetsService] API Error: StatusCode \(httpResponse.statusCode), Body: \(errorText)")
            
            // Check for API Disabled / Unenabled Error
            if httpResponse.statusCode == 403 || httpResponse.statusCode == 400 {
                let pID = extractProjectID(from: errorText)
                
                if errorText.contains("sheets.googleapis.com") || errorText.contains("Sheets API") {
                    throw NSError(
                        domain: "GoogleSheetsService",
                        code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "您尚未在 Google 專案啟用「Google Sheets API」。\n\n請以瀏覽器 [點擊此處開啟 Google Cloud 主控台](https://console.developers.google.com/apis/api/sheets.googleapis.com/overview?project=\(pID)) 點擊「啟用 (Enable)」服務後，再重新進行對接同步。"
                        ]
                    )
                }
                
                if errorText.contains("drive.googleapis.com") || errorText.contains("Drive API") {
                    throw NSError(
                        domain: "GoogleSheetsService",
                        code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "您尚未在 Google 專案啟用「Google Drive API」。\n\n請以瀏覽器 [點擊此處開啟 Google Cloud 主控台](https://console.developers.google.com/apis/api/drive.googleapis.com/overview?project=\(pID)) 點擊「啟用 (Enable)」服務後，再重試。"
                        ]
                    )
                }
            }
            
            throw NSError(domain: "GoogleSheetsService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Google 雲端錯誤 (\(httpResponse.statusCode))：\(errorText)"])
        }
        
        return data
    }
    
    private func extractProjectID(from errorText: String) -> String {
        if let range = errorText.range(of: "project=") {
            let sub = errorText[range.upperBound...]
            let pID = sub.prefix(while: { $0.isNumber || $0 == "_" || $0 == "-" })
            if !pID.isEmpty {
                return String(pID)
            }
        }
        if let range = errorText.range(of: "project ") {
            let sub = errorText[range.upperBound...]
            let pID = sub.prefix(while: { $0.isNumber })
            if !pID.isEmpty {
                return String(pID)
            }
        }
        if let range = errorText.range(of: "projects/") {
            let sub = errorText[range.upperBound...]
            let pID = sub.prefix(while: { $0.isNumber })
            if !pID.isEmpty {
                return String(pID)
            }
        }
        return "516991619764"
    }
    
    // MARK: - Google Drive API (Browse files)
    
    func fetchSpreadsheets() async throws -> [GoogleDriveFile] {
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: "mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false"),
            URLQueryItem(name: "orderBy", value: "modifiedTime desc"),
            URLQueryItem(name: "pageSize", value: "50"),
            URLQueryItem(name: "fields", value: "files(id, name, mimeType)")
        ]
        
        let data = try await performRequest(url: components.url!, method: "GET")
        let response = try JSONDecoder().decode(GoogleDriveListResponse.self, from: data)
        return response.files
    }
    
    // MARK: - Google Sheets API (Create & Configure)
    
    func createNewSpreadsheet(title: String) async throws -> GoogleDriveFile {
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets")!
        
        // Define initial sheets when creating
        let requestBody: [String: Any] = [
            "properties": [
                "title": title
            ],
            "sheets": [
                ["properties": ["title": "客戶資料 (Customers)"]],
                ["properties": ["title": "預約記錄 (Appointments)"]],
                ["properties": ["title": "療程方案 (Packages)"]],
                ["properties": ["title": "財務發票 (Invoices)"]]
            ]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        let data = try await performRequest(url: url, method: "POST", body: bodyData)
        
        let response = try JSONDecoder().decode(GoogleCreateSheetResponse.self, from: data)
        return GoogleDriveFile(id: response.spreadsheetId, name: title, mimeType: "application/vnd.google-apps.spreadsheet")
    }
    
    func fetchWorksheets(spreadsheetID: String) async throws -> [String] {
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID)")!
        
        let data = try await performRequest(url: url, method: "GET")
        let response = try JSONDecoder().decode(GoogleCreateSheetResponse.self, from: data)
        return response.sheets.map { $0.properties.title }
    }
    
    func ensureWorksheetsExist(spreadsheetID: String, titles: [String]) async throws {
        let existingTitles = try await fetchWorksheets(spreadsheetID: spreadsheetID)
        let missingTitles = titles.filter { !existingTitles.contains($0) }
        
        guard !missingTitles.isEmpty else { return }
        
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID):batchUpdate")!
        
        let requests = missingTitles.map { title -> [String: Any] in
            return [
                "addSheet": [
                    "properties": [
                        "title": title
                    ]
                ]
            ]
        }
        
        let requestBody = ["requests": requests]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        _ = try await performRequest(url: url, method: "POST", body: bodyData)
        print("[GoogleSheetsService] Successfully added missing sheets: \(missingTitles)")
    }
    
    // MARK: - Write Row Matrix
    
    func overwriteWorksheet(spreadsheetID: String, sheetTitle: String, headers: [String], rows: [[String]]) async throws {
        // Prepare matrix: Headers first, followed by data rows
        var matrix: [[String]] = [headers]
        matrix.append(contentsOf: rows)
        
        // 1. Clear existing content in the sheet
        let clearURL = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID)/values/\(sheetTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!):clear")!
        _ = try await performRequest(url: clearURL, method: "POST")
        
        // 2. Write new matrix values
        let updateURL = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID)/values/\(sheetTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)?valueInputOption=USER_ENTERED")!
        
        let requestBody: [String: Any] = [
            "range": sheetTitle,
            "majorDimension": "ROWS",
            "values": matrix
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        _ = try await performRequest(url: updateURL, method: "PUT", body: bodyData)
        
        print("[GoogleSheetsService] Overwrote '\(sheetTitle)' with \(rows.count) rows of data.")
    }
    
    func fetchWorksheetValues(spreadsheetID: String, range: String) async throws -> [[String]] {
        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetID)/values/\(encodedRange)")!
        
        let data = try await performRequest(url: url, method: "GET")
        let response = try JSONDecoder().decode(GoogleSheetValuesResponse.self, from: data)
        
        guard let valuesMatrix = response.values else { return [] }
        return valuesMatrix.map { row in row.map { $0.stringValue } }
    }
}

// MARK: - API Decodable Decoders

private struct GoogleDriveListResponse: Codable {
    let files: [GoogleDriveFile]
}

private struct GoogleCreateSheetResponse: Codable {
    let spreadsheetId: String
    let sheets: [GoogleSheetWrapper]
}

private struct GoogleSheetWrapper: Codable {
    let properties: GoogleSheetProperties
}

private struct GoogleSheetProperties: Codable {
    let title: String
}

private struct GoogleSheetValuesResponse: Codable {
    let range: String
    let majorDimension: String
    let values: [[GoogleCell]]?
}

struct GoogleCell: Codable {
    let stringValue: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self.stringValue = s
        } else if let i = try? container.decode(Int.self) {
            self.stringValue = String(i)
        } else if let d = try? container.decode(Double.self) {
            self.stringValue = String(d)
        } else if let b = try? container.decode(Bool.self) {
            self.stringValue = String(b)
        } else {
            self.stringValue = ""
        }
    }
}
