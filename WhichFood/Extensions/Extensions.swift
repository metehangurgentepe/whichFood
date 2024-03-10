//
//  Extensions.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.09.2023.
//

import Foundation
import Firebase
import UIKit

// MARK: Public showAlert function
public func showAlert(title: String, message: String, buttonTitle: String, secondButtonTitle: String?, completionHandler: (() -> Void)? = nil, completionSecondHandler: (() -> Void)? = nil) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: buttonTitle, style: .default) { _ in
        completionHandler?()
    }
    
    if let secondButtonTitle = secondButtonTitle {
           let secondAction = UIAlertAction(title: secondButtonTitle, style: .default) { _ in
               completionSecondHandler?()
           }
           alertController.addAction(secondAction)
    }
    alertController.addAction(okAction)
    
    return alertController
}





public func formatDate(_ timestamp: Timestamp?) -> String? {
    guard let timestamp = timestamp else {
        return nil
    }

    let date = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMMM yyyy"
    return dateFormatter.string(from: date)
}





