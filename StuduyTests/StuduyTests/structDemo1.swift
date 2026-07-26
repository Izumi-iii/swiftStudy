//
//  structDemo1.swift
//  
//
//  Created by 1-6 on 2026/7/25.
//

struct Temperature{
    var celsius:Double
    
    
    //计算属性：华氏温度
    var fahrenheit: Double{
        get{
            return celsius * 9/5 + 32
        }
        set {
            celsius = (newValue - 32) * 5/9
        }
    }
    
    //计算属性：开尔文温度
    var kelvin:Double{
        return celsius + 273.15
    }
    
    static let absoluteZero = Temperature(celsisus: -273.15)
    
    //判断是否低于绝对零度
    var isValid:Bool{
        return celsius >= -273.13
    }
}

var temp = Temperature(celsius:25)
print("摄氏:\(temp.celsius)C")
print("华氏:\(temp.celsius)F")
print("开尔文:\(temp.celsius)K")

temp.fahrenheit = 98.6
print("对应摄氏度:\(temp.celsius)C")

