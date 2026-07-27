//
//  enumDemoNetworkError.swift
//  studyDemo
//
//  Created by wangjie on 2026/7/27.
//

import Foundation

func runNetworkError(){
    
    //让枚举遵循协议
    enum NetworkError: Error, CustomStringConvertible {
        case notFound(url: String)
        case timeout(seconds: Int)
        case unauthorized
        case serverError(code: Int)
        
        var description: String {
            switch self {
            case .notFound(let url):
                return "404 找不到页面：\(url)"
            case .timeout(let seconds):
                return "请求超时（\(seconds)秒）"
            case .unauthorized:
                return "未授权访问"
            case .serverError(let code):
                return "服务器错误，状态码：\(code)"
            }
        }
    }
    
    //作为 Error 使用
    func fetchData() throws {
        throw NetworkError.timeout(seconds: 30)
    }
    
    do {
        try fetchData()
    } catch let error as NetworkError {
        print(error.description)
    } catch {
        print("未知错误")
    }
    
    //使用 Comparable 协议
    enum LogLevel: Int,Comparable{
        case debug = 0, info, warning, error, critical
        
        static func < (lhs: LogLevel,rhs: LogLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        var emoji: String {
            switch self{
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
    }
    
    let log1 = LogLevel.warning
    let log2 = LogLevel.error
    print(log1 < log2) //   true
    print("\(log1.emoji) 警告信息")
    
    
}
