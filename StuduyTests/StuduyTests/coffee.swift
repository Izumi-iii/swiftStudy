//
//  coffee.swift
//  StuduyTests
//
//  Created by wangjie on 2026/7/23.
//

import Foundation

func makeCoffee() async  -> String {
    print("1.start make coffe")
    
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    print("2.comleted")
    
    return "🍵"
}


//@main
//struct AsyncDemo {
//    static func main() async {
//        print("程序开始")
//        
//        let coffee = await makeCoffee()
//        
//        print("3. i have a \(coffee)")
//        
//        print("程序结束")
//    }
//}
