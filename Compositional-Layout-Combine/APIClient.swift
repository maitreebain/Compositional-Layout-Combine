//
//  APIClient.swift
//  Compositional-Layout-Combine
//
//  Created by Maitree Bain on 8/25/20.
//  Copyright © 2020 Maitree Bain. All rights reserved.
//

import UIKit
import Combine

struct PhotoResultsWrapper: Decodable {
  let hits: [Photo]
}

struct Photo: Decodable, Hashable {
  let id: Int
  let webformatURL: String
}

class APIClient {
    
    public func searchPhotos(for query: String) -> AnyPublisher<[Photo], Error> {
        let perPage = 200
        
        let query = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "opal"
        
        let endpoint = "https://pixabay.com/api/?key=\(Config.APIKey)&q=\(query)&per_page=\(perPage)&safesearch=true"
        
        let url = URL(string: endpoint)!
        
        return URLSession.shared.dataTaskPublisher(for: url).map(\.data)
            .decode(type: PhotoResultsWrapper.self, decoder: JSONDecoder()).map{ $0.hits}
            .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
