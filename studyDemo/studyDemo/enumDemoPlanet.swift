//
//  Untitled.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation

func runPlanet(){
    enum Planet:String{
        case mercury = "水星"
        case venus = "金星"
        case earth = "地球"
        case mars = "火星"
    }
    
    //如果不指定，默认原始值等于case名称
    enum Animal: String{
        case dog
        case cat
        case bird
    }
    
    let earth = Planet.earth
    print(earth.rawValue)   // 地球
    print(Animal.dog.rawValue)  // dog
}
