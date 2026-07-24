//
//  NetworkAlertVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 16.07.2024.
//

import UIKit

class NetworkAlertVC: DataLoadingVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkInternetConnection()
    }
    
    func checkInternetConnection() {
        if !NetworkMonitor.shared.isConnected {
            showAlert()
        }
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "İnternet Bağlantısı Yok", message: "İnternet bağlantınızın olduğundan emin olun.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
