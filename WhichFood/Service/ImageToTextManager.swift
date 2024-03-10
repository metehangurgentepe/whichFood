//
//  ImageToTextManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 4.12.2023.
//

import Foundation
import Alamofire


class ImageToTextManager {
    static let shared = ImageToTextManager()
    
    private init(){}
    
    func postImage(url: String) async throws -> TextModel {
        let apiUrl = "https://europe-west3-whichfood-983f1.cloudfunctions.net/postImage"

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
        ]

        let parameters: [String: Any] = ["message": url]

        return try await withCheckedThrowingContinuation { continuation in
            AF.request(apiUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .responseDecodable(of: TextModel.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}
