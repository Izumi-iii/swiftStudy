//
//  closure.swift
//  StuduyTests
//
//  Created by wangjie on 2026/7/23.
//

/*
 闭包的基本格式
 { (参数) -> 返回值类型 in
     代码
 }
 */

import Foundation

func calculate(_ a:Int,_ b:Int,operation:(Int,Int) -> Int) -> Int{
    return operation(a,b)
}

func doSomething(action:() -> Void ){
    print("start")
    action()
    print("end")
}

//@main
struct closureDemo {
    static func main() {
        let addClosure = { (a:Int,b:Int) -> Int in
            return a + b
        }
        
        let result = addClosure(1, 2)
        print(result)
        
        let greetClosure = { (name:String) -> String in
            return "Hello, \(name)"
            
        }
        let greet = greetClosure("Jack")
        print(greet)
        
//        let sorted = numbers.sorted { a,b in
//            return a < b
//        }
//        let sorted = numbers.sorted(by:<)
        //简化写法
        
        var count = 0
        let increase = {
            count += 1
            print(count)
        }
        
        increase()
        increase()
        increase()
        /*
         闭包里面没有定义 count，但它记住了外面的 count。这叫 捕获变量。
         也就是说，闭包不是只保存代码，有时候还会保存它用到的外部环境。
         */
        
        var x = 10
        
        let closure = {
            print(x)
        }
        
        x = 20
        
        closure() //10 这个闭包捕获的是外部变量x本身，而不是创建闭包那一刻的值。
        
        //如果函数的最后一个参数是闭包，可以把这个闭包拿到小括号外面写。
        let result1 = calculate(3, 5) { x,y in
            x + y
        }
        
        print(result1)
        
        doSomething {
            print("do something")
        }
        
    }
}
