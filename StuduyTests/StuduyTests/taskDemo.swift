//
//  taskDemo.swift
//  StuduyTests
//
//  Created by wangjie on 2026/7/23.
//

import Foundation

func makeCoffe2() async -> String {
    print("start making coffe")
    
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    return "☕️"
}

func function1() async {
    print("a")
    
    let coffee = await makeCoffe2()
    
    print(coffee)
    
    print("b")
    
}

func function2() {
    print("a")
    
    Task {
        let coffee = await makeCoffe2()
        
        print(coffee)
        
        
    }
    print("b")
}

//@main
struct asyncAndTask {
    static func main() async {
        await function1()
        
        function2()
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
