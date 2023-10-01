//
//  APICaller.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.09.2023.
//

import Foundation
import OpenAISwift
import OpenAIKit

final class APICaller {
    static let shared = APICaller()
    
    @frozen enum Constants{
        static let key = "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"
       // static let orgName = "Personal"
    }
    
    private var client : OpenAISwift?
    
    private init() {}
  //  let openAI = OpenAISwift(authToken: "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") // bu eski test key
    
   

    public let openAI = OpenAIKit(apiToken: Constants.key)
    
    public func setup() {
        self.client = OpenAISwift(authToken: Constants.key)
       
    }
    
    public func getResponse(input: String, completion: @escaping (Result<String,Error>) -> Void){
        openAI.sendCompletion(prompt: input, model: .gptV3_5(.davinciText003), maxTokens: 1000) { result in
            switch result {
            case .success(let aiResult):
                DispatchQueue.main.async {
                    if let text = aiResult.choices.first?.text {
                        print("response text: \(text)") //"\n\nHello there, how may I assist you today?"
                        completion(.success(text))
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
