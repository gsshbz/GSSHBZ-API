//
//  ArmoryMigrations.swift
//
//
//  Created by Mico Miloloza on 30.10.2023..
//

import Vapor
import Fluent


enum ArmoryMigrations {
    struct v1: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(ArmoryCategoryModel.schema)
                .id()
                .field(ArmoryCategoryModel.FieldKeys.v1.name, .string, .required)
                .create()
            
            
            try await database.schema(ArmoryItemModel.schema)
                .id()
                .field(ArmoryItemModel.FieldKeys.v1.name, .string, .required)
                .field(ArmoryItemModel.FieldKeys.v1.imageKey, .string, .required)
                .field(ArmoryItemModel.FieldKeys.v1.aboutInfo, .string, .required)
                .field(ArmoryItemModel.FieldKeys.v1.categoryId, .uuid)
                .field(ArmoryItemModel.FieldKeys.v1.inStock, .int64, .required, .sql(.default(0)))
                .foreignKey(ArmoryItemModel.FieldKeys.v1.categoryId,
                            references: ArmoryCategoryModel.schema,
                            .id,
                            onDelete: .setNull,
                            onUpdate: .cascade)
                .unique(on: ArmoryItemModel.FieldKeys.v1.name)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(ArmoryCategoryModel.schema).delete()
            try await database.schema(ArmoryItemModel.schema).delete()
            
        }
    }
    
    struct v2: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema(ArmoryCategoryModel.schema)
                .field(ArmoryCategoryModel.FieldKeys.v2.imageKey, .string)
                .update()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema(ArmoryCategoryModel.schema)
                .deleteField(ArmoryCategoryModel.FieldKeys.v2.imageKey)
                .update()
        }
    }
    
    struct seed: AsyncMigration {
        func prepare(on database: Database) async throws {
            let defaultCategory = ArmoryCategoryModel(name: "Default")
            try await defaultCategory.create(on: database)
            
            let carabinerCategory = ArmoryCategoryModel(name: "Carabiner")
            try await carabinerCategory.create(on: database)
            
            let belaysAndDescendersCategory = ArmoryCategoryModel(name: "Belays and Descenders")
            try await belaysAndDescendersCategory.create(on: database)
            
            let helmetCategory = ArmoryCategoryModel(name: "Helmet")
            try await helmetCategory.create(on: database)
            
            let armoryItems = [
                ArmoryItemModel(
                    name: "William karabiner",
                    imageKey: "william.jpeg",
                    aboutInfo: "Petzl William asimetrični karabiner visokog kapaciteta. Sa svojim kruškolikim oblikom pogodan je za ukopčavanje više komada opreme. Unutarnji fluidan dizajn i Keylock sustav olakšavaju rukovanje karabinerom. Karabiner dolazi u 3 vrste sustava za zatvaranje: karabiner s maticom (SCREW-LOCK), automatsko zatvaranje (TRIACT-LOCK, BALL-LOCK) Certifikati: CE EN 362, EAAC, NFPA 1983 Technical Use",
                    categoryId: carabinerCategory.id!,
                    inStock: 10),
                ArmoryItemModel(
                    name: "OK karabiner",
                    imageKey: "carabiner-ok.jpeg",
                aboutInfo: "Petzl OK aluminijski karabiner s maticom za optimalno pozicioniranje opreme. Idealan za osiguravanje i spuštanje te izradu konstrukcija za podizanje, spuštanje i transport. Dostupno u tri verzije zaključavanja: SCREW-LOCK, TRIACT-LOCK, BALL-LOCK",
                    categoryId: carabinerCategory.id!,
                    inStock: 10),
                ArmoryItemModel(
                    name: "GRIGRI",
                    imageKey: "grigri.jpeg",
                aboutInfo: "GRIGRI + uređaj za osiguravanje. Pogodan za sve penjače na vanjskim ili unutrašnjim stijenama. Pogodan za upotrebu na užadi debljine 8,9mm – 10,5mm. Pogodan za intenzivniju upotrebu. Sigurnosna ručica (anti-panic) za spuštanje penjača partnera. Sistem za odabir načina penjanja: “top rope” ili “lead”. Pogodan za početnike penjače. Težina: 200g. Certifikati: CE EN 15151-1, UIAA",
                    categoryId: carabinerCategory.id!,
                    inStock: 10),
                ArmoryItemModel(
                    name: "Petzl Boreo Caving kaciga",
                    imageKey: "petzl-boreo-caving.jpeg",
                aboutInfo: "BOREO CAVING je kaciga posebno dizajnirana za speleologiju. Opremljena montažnim pločama naprijed i na stražnjoj strani kacige za postavljanje DUO RL, DUO S ili DUO Z2 svjetiljke. Dizajn pruža veću pokrivenost i stražnji dio je niži za poboljšanu zaštitu od padajućih kamenja, kao i od bočnih, frontalnih i stražnjih udaraca. Tvrdi vanjski oklop otporan je na udarce i ogrebotine za optimalnu trajnost. Stabilna prilikom nošenja, s fleksibilnom trakom za glavu koja se prilagođava obliku glave. Certifikati: CE EN 12492, UIAA",
                    categoryId: helmetCategory.id!,
                    inStock: 10),
                
                ArmoryItemModel(
                    name: "Armory item with default category",
                    imageKey: "petzl-boreo-caving.jpeg",
                aboutInfo: "Some about info description bla bla bla bla bla bla",
                    categoryId: defaultCategory.id!,
                    inStock: 5)
            ]
            
            try await armoryItems.create(on: database)
        }
        
        func revert(on database: Database) async throws {
            try await ArmoryItemModel.query(on: database).delete()
            try await ArmoryCategoryModel.query(on: database).delete()
        }
    }
}
