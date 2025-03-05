import Foundation

// API错误类型
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(String)
    case unknown
    case unauthorized
    case noData
}

// 网络错误类型
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    case decodingFailed(Error)
    case serverError(String)
    case unknown
    case unauthorized
}

// 错误响应结构体已移至APIModels.swift
