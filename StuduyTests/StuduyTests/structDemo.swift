//
//  structDemo.swift
//  
//
//  Created by 1-6 on 2026/7/25.
//

struct Book{
    var title:String
    var author:String
    var pages:Int
    var price:Double
    
    var  isThickBook{
        return pages>300
    }
    
    func description() -> String{
        return "《\(title)》 作者：\(author)，共\(pages)页，价格：¥\(price)"
    }
}

let book1 = Book(title:"Swift编程",author:"Apple",pages:500,price:69.00)
print(book1.description())
print("是否厚书：\(book1.isThickBook)")

struct Point3D{
    var x:Double
    var y:Double
    var z:Double
    
    var distanceFromOrigin:Double{
        return sqrt(x*x + y*y + z*z)
    }
    
    mutating func translate(dx:Double,dy:Double,dz:Double){
        x += dx
        y += dy
        z += dz
    }
    
}

var point = Point3D(x:3,y:4,z:0)
print("到原点距离：\(point.distanceFromOrigin)")
point.translate(dx:1,dy:1,dz:5)
print("移动后：\(point)")
