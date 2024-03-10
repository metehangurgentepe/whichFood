//
//  Array + Ext.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.02.2024.
//

import Foundation


// MARK: For Buttons
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, self.count)])
        }
    }
}
