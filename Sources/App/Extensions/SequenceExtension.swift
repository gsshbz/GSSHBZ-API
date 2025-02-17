//
//  SequenceExtension.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 17.02.2025..
//


extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
        var results = [T]()
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }
}
