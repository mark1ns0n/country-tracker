//
//  AppModelSchema.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

enum AppModelSchema {
    static let schema = Schema(versionedSchema: AppSchemaV2.self)

    static func makeContainer(
        inMemory: Bool,
        url: URL? = nil
    ) throws -> ModelContainer {
        let configuration = configuration(
            inMemory: inMemory,
            url: url
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func legacySchema() -> Schema {
        Schema(versionedSchema: AppSchemaV1.self)
    }

    private static func configuration(
        inMemory: Bool,
        url: URL?
    ) -> ModelConfiguration {
        if let url {
            return ModelConfiguration(
                "CountryDaysTracker",
                schema: schema,
                url: url,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        }

        // Use the default unnamed SwiftData configuration for the production store so the
        // app continues reading the existing on-device `default.store` database.
        return ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
    }
}
