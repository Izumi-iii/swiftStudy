//
//  enumDemoNetwork.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation

//网络请求结果

func runNetwork(){
    enum NetworkResult{
        case success(data:String)
        case failure(error:String)
        case  loading(progress:Double)
    }
    
    func handleResult(_ result: NetworkResult){
        switch result {
        case .success(let data):
            print("成功：\(data)")
        case .failure(let error):
            print("失败：\(error)")
        case .loading(let progress):
            print("加载中：\(Int(progress * 100))%")
        }
    }
    
    handleResult(.success(data: "用户数据加载完成"))
    handleResult(.loading(progress: 0.65))
    handleResult(.failure(error: "网络连接超时"))
    
}
