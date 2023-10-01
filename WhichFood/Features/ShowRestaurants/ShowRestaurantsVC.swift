//
//  ShowRestaurantsVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.09.2023.
//

import UIKit
import GooglePlaces

class ShowRestaurantsVC: UIViewController {
    // Add a pair of UILabels in Interface Builder, and connect the outlets to these variables.
       private var nameLabel = UILabel()
       private var addressLabel = UILabel()
        private let button = UIButton()

      private var placesClient: GMSPlacesClient!

      override func viewDidLoad() {
        super.viewDidLoad()
          view.backgroundColor = .white
        placesClient = GMSPlacesClient.shared()
          nameLabel.text = "name"
          addressLabel.text = "adress"
          nameLabel.frame = CGRect(x: 200, y: 200, width: 50, height: 100)
          addressLabel.frame = CGRect(x: 200, y: 400, width: 50, height: 100)
          
          button.setTitle("button", for: .normal)
          button.frame = CGRect(x: 200, y: 500, width: 200, height: 50)
          
          button.addTarget(self, action: #selector(getCurrentPlace), for: .touchUpInside)
          
          view.addSubview(nameLabel)
          view.addSubview(addressLabel)
          view.addSubview(button)
          
          
      }

      // Add a UIButton in Interface Builder, and connect the action to this function.
    @objc func getCurrentPlace() {
        let placeFields: GMSPlaceField = [.name, .formattedAddress]
        placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: placeFields) { [weak self] (placeLikelihoods, error) in
          guard let strongSelf = self else {
            return
          }

          guard error == nil else {
            print("Current place error: \(error?.localizedDescription ?? "")")
            return
          }

          guard let place = placeLikelihoods?.first?.place else {
            strongSelf.nameLabel.text = "No current place"
            strongSelf.addressLabel.text = ""
            return
          }

          strongSelf.nameLabel.text = place.name
          strongSelf.addressLabel.text = place.formattedAddress
        }
      }
}
