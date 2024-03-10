//
//  ChatGptResponseModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.11.2023.
//

import Foundation


struct ChatGptResponseModel: Decodable{
    let text: String
    let index: Int
    let logprobs: String?
    let finish_reason: String
}
