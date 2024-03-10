//
//  Date+Ext.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.02.2024.
//

import Foundation
import Firebase

extension Date {
    func formatDate(_ timestamp: Timestamp?) -> String? {
        guard let timestamp = timestamp else {
            return nil
        }

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}
