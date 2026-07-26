//
//  structDemoCircle.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation

func runCircle(){
    //实现自定义协议
    protocol Shape{
        var area: Double { get }
        func description() -> String
    }
    
    struct Circle: Shape {
        var radius: Double
        
        var area:Double {
            return .pi * radius * radius
        }
        
        var perimeter: Double{
            return 2 * .pi * radius
        }
        
        func description() -> String {
            return "圆形：半径 \(radius) ，面积 \(String(format:"%.2f",area))"
        }
    }
    
    struct Rectang: Shape {
        var width: Double
        var height: Double
        
        var area: Double {
            return 2 * (width + height)
        }
        
        var isSquare: Bool {
            return width == height
        }
        
        func description() -> String {
            let shape = isSquare ? "正方形" : "矩形"
            return "\(shape):\(width)X\(height),面积\(area)"
            
        }
    }
    
    let shapes:[Shape] = [
        Circle(radius: 5),
        Rectang(width: 4, height: 4),
        Rectang(width: 3, height: 6)
    ]
    
    for shape in shapes {
        print(shape.description())
    }
    
}
