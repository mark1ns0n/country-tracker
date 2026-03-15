//
//  AppModelSchema.swift
//  CountryDaysTracker
//
//  Created on 14 March 2026.
//

import Foundation
import SwiftData

enum AppModelSchema {
    private static let appGroupIdentifier = "group.com.mark1ns0n.countrydaystracker"
    private static let persistentStoreFilename = "default.store"
    static let schema = Schema(versionedSchema: AppSchemaV2.self)

    static func makeContainer(
        inMemory: Bool,
        url: URL? = nil
    ) throws -> ModelContainer {
        if !inMemory, url == nil {
            try ensurePersistentStoreDirectoryExists()
        }
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
        if let url = url ?? defaultPersistentStoreURL() {
            return ModelConfiguration(
                "CountryDaysTracker",
                schema: schema,
                url: url,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        }

        return ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
    }

    private static func defaultPersistentStoreURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }

        return containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(persistentStoreFilename, isDirectory: false)
    }

    private static func ensurePersistentStoreDirectoryExists() throws {
        guard let storeURL = defaultPersistentStoreURL() else { return }
        let directoryURL = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}
