//
//  enumDemoTrafficLight.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation

func runTrafficLight(){
    enum TrafficLight{
        case red,yellow,green
        
        //方法
        func description() -> String {
            switch self {
            case .red: return "停止"
            case .yellow: return "注意"
            case .green:return "通行"
            }
        }
        
        //mutating 方法：改变自身
        mutating func next(){
            switch self{
            case .red:self = .green
            case .green:self = .yellow
            case .yellow:self = .red
            }
        }
        
        var duration: Int {
            switch self{
            case .red: return 30
            case .yellow: return 5
            case .green:return 25
            }
        }
    }
    var light = TrafficLight.red
    print(light.description()) //停止
    print("持续\(light.duration)秒")
    
    light.next()
    print(light.description()) //通行
    
}
