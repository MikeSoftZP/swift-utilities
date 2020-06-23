//
//  Codable+Helper.swift
//  swift-utilities
//
//  Created by Mike Ponomaryov on 05.06.2020.
//  Copyright © 2020 illutex. All rights reserved.
//

import Foundation

extension Decodable {
    static func object <T: Codable> (from json: String, dateFormat: String? = nil, class: T.Type) -> T? {
        guard let jsonData = json.data(using: .utf8) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            
            if let dateFormat = dateFormat {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = dateFormat
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
            }
            
            let object = try decoder.decode(T.self, from: jsonData)
            return object
        } catch {
            print("error while decoding: \(error)")
        }
        
        return nil
    }
}

extension Encodable {
    func jsonRepresentation() -> String? {
        let encoder = JSONEncoder()
//        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(self)
            let json = String(data: jsonData, encoding: .utf8)
            return json
        }catch {
            print("error while encoding: \(error)")
        }
        
        return nil
    }
}
