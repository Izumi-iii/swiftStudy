//
//  enumDemoDay.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation

//带原始值的枚举

func runDay(){
    enum Weekday:Int{
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6
        case sunday = 7
    }
    
    //Int类型的原始值会自动递增
    enum Month:Int {
        case january = 1,february,march,april,may,june,july,august,september,october,november,december
    }
    
    let today = Weekday.friday
    print(today.rawValue) //5
    
    //通过原始值创建枚举（返回可选类型）
    let day = Weekday(rawValue: 3)
    print(day ?? "无效")  //wednesday
    
    let invalidDay = Weekday(rawValue: 10)
    print(day ?? "无效")  //无效
    
    
}
