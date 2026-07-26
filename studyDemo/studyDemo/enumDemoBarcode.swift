//
//  enumDemoBarcode.swift
//  studyDemo
//
//  Created by 1-6 on 2026/7/26.
//

import Foundation

//带关联值的枚举
func runBarcode(){
    enum Barcode{
        case upc(Int,Int,Int,Int)
        case qrCode(String)
    }
    
    var productBarcode = Barcode.upc(8, 85909, 51226, 3)
    productBarcode = Barcode.qrCode("BAJJJHJDSJKJAD")
    
    //在switch中提取关键值
    switch productBarcode {
    case .upc(let numberSystem, let manufacturer, let product, let check):
        print("UPC:\(numberSystem)-\(manufacturer)-\(product)-\(check)")
    case .qrCode(let code):
        print("QR码:\(code)")
    }
}
