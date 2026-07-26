//
//  enumDemoDirection.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation


//最简单的枚举
func runDirecion(){
    enum Direction{
        case north
        case south
        case east
        case west
    }
    
    var dir = Direction.north
    print(dir)  //north
    
    dir = .south    //一旦确定了枚举类型，可以用简短写法
    print(dir)
    
    switch dir {
    case .north:
        print("往北走")
    case .south:
        print("往南走")
    case .west:
        print("往西走")
    case .east:
        print("往东走")
    }
    
    
    
}
