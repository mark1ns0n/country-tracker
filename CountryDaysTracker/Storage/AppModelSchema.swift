//
//  AppModelSchema.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import SwiftData

enum AppModelSchema {
    static let schema = Schema([
        StayInterval.self,
        LocationEventLog.self,
        ResidencyProfile.self,
    ])

    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
