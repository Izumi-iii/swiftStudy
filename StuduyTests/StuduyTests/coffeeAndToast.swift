//
//  coffeeAndToast.swift
//  StuduyTests
//
//  Created by wangjie on 2026/7/23.
//

import Foundation

func makeCoffe() async -> String {
    print("start making coffe")
    
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    return "☕️"
}

func makeToast() async -> String {
    print("start making toast")
    
    try? await Task.sleep(nanoseconds: 3_000_000_000)
    
    return "🥘"
}

//@main
struct AsyncDemo {
    static func main() async{
        //这个会花2+3=5秒。因为要先等咖啡做完，才能做面包
//        let coffe = await makeCoffe()
//        let toast = await makeToast()
//        
//        print("breakfast is \(coffe) and \(toast)")
        
        //这个只会儿花3秒，因为咖啡和面包同时开始做
        async let coffe = makeCoffe()
        async let toast = makeToast()
        let breakfast = await "\(coffe) and \(toast)"
        
        print("breakfast: \(breakfast)")
    }
}
