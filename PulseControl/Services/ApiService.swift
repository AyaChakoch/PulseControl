//
//  ApiService.swift
//  PulseControl
//
//  Created by Aya on 2025-12-16.
//

import Foundation



// MARK: - Models

struct PulseAnalyzeRequest: Codable {
    let bpm: Int
}

struct PulseAnalyzeResponse: Codable {
    let bpm: Int
    let category: String
    let message: String
    let recommendation: String
}

struct ApiErrorResponse: Codable {
    let errorCode: String?
    let message: String
}


// MARK: - Errors

enum ApiServiceError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case server(statusCode: Int, message: String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .transport(let error):
            return error.localizedDescription
        case .server(_, let message):
            return message
        case .decoding:
            return "Failed to read server response."
        }
    }
}


// MARK: - ApiService

class ApiService {


    private let baseURL = "http://192.168.0.12:3000"


    func analyzePulse(bpm: Int) async throws -> PulseAnalyzeResponse {

        guard let url = URL(string: "\(baseURL)/api/pulse/analyze") else {
            throw ApiServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PulseAnalyzeRequest(bpm: bpm)
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ApiServiceError.server(statusCode: -1, message: "No HTTP response")
            }

            // Success
            if (200...299).contains(httpResponse.statusCode) {
                guard let decoded = try? JSONDecoder().decode(PulseAnalyzeResponse.self, from: data) else {
                    throw ApiServiceError.decoding
                }
                return decoded
            }

            // Error från backend
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiServiceError.server(
                    statusCode: httpResponse.statusCode,
                    message: apiError.message
                )
            } else {
                throw ApiServiceError.server(
                    statusCode: httpResponse.statusCode,
                    message: "Server error (\(httpResponse.statusCode))"
                )
            }

        } catch let error as ApiServiceError {
            throw error
        } catch {
            throw ApiServiceError.transport(error)
        }
    }
}
