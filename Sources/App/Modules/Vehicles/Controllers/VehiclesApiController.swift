//
//  VehiclesApiController.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 16.09.2025..
//


import Vapor
import Fluent


extension Armory.Vehicle.Create: Content {}
extension Armory.Vehicle.Detail: Content {}
extension Armory.Vehicle.List: Content {}
extension Armory.TripHistory.Detail: Content {}


struct VehiclesApiController: ListController {
    
    typealias ApiModel = Armory.Vehicle
    typealias DatabaseModel = VehicleModel
    typealias CreateObject = Armory.Vehicle.Create
    typealias UpdateObject = Armory.Vehicle.Update
    typealias DetailObject = Armory.Vehicle.Detail
    typealias PatchObject = Armory.Vehicle.Patch
    typealias ListObject = Armory.Vehicle.List
    
    var parameterId: String = "vehicleId"
    
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        baseRoutes.on(.GET, use: listApi)
        baseRoutes.on(.POST, use: createApi)
        
        existingModelRoutes.on(.GET, use: detailApi)
        existingModelRoutes.on(.POST, use: updateApi)
        existingModelRoutes.on(.DELETE, use: deleteApi)
        existingModelRoutes.on(.POST, "create-new-trip", use: createNewTrip)
        existingModelRoutes.on(.PATCH, use: patchApi)
    }
}


extension VehiclesApiController {
    func createApi(_ req: Request) async throws -> DetailObject {
        let input = try req.content.decode(CreateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let _ = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        // Create new Vehicle
        let newVehicle = try VehicleModel(maker: input.maker, model: input.model, year: input.year, odometer: input.odometer, imageKey: input.imageKey)
        try await newVehicle.save(on: req.db)
        
        let detailOutput = DetailObject(id: try newVehicle.requireID(),
                                        maker: newVehicle.maker,
                                        model: newVehicle.model,
                                        year: newVehicle.year,
                                        odometer: newVehicle.odometer,
                                        imageKey: newVehicle.imageKey,
                                        tripHistory: [],
                                        createdAt: newVehicle.createdAt,
                                        updatedAt: newVehicle.updatedAt,
                                        deletedAt: newVehicle.deletedAt)
        
        return detailOutput
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let vehicleModel = try await findBy(identifier(req), on: req.db)
        
        // Delete the VehicleModel
        try await vehicleModel.delete(on: req.db)
        
        return .noContent
    }
    
    func detailApi(_ req: Request) async throws -> DetailObject {
        guard let vehicleModel = try await DatabaseModel.query(on: req.db)
            .with(\.$tripHistory)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.vehicleNotFound
        }
        
        // Load user object for every trip history model
        for tripHistory in vehicleModel.tripHistory {
            try await tripHistory.$user.load(on: req.db)
        }
        
        return .init(id: try vehicleModel.requireID(),
                     maker: vehicleModel.maker,
                     model: vehicleModel.model,
                     year: vehicleModel.year,
                     odometer: vehicleModel.odometer,
                     imageKey: vehicleModel.imageKey,
                     tripHistory: try vehicleModel.tripHistory.map { .init(id: try $0.requireID(), distance: $0.distance, odometer: $0.odometer, destination: $0.destination, createdAt: $0.createdAt, user: .init(id: try $0.user.requireID(), firstName: $0.user.firstName, lastName: $0.user.lastName, imageKey: $0.user.imageKey)) },
                     createdAt: vehicleModel.createdAt,
                     updatedAt: vehicleModel.updatedAt,
                     deletedAt: vehicleModel.deletedAt)
    }
    
    func updateApi(_ req: Request) async throws -> DetailObject {
        let updateObject = try req.content.decode(UpdateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let _ = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        guard let vehicleModel = try await DatabaseModel.query(on: req.db)
            .with(\.$tripHistory)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.vehicleNotFound
        }
        
        // Load user object for every trip history model
        for tripHistory in vehicleModel.tripHistory {
            try await tripHistory.$user.load(on: req.db)
        }
        
        vehicleModel.maker = updateObject.maker
        vehicleModel.model = updateObject.model
        vehicleModel.imageKey = updateObject.imageKey
        vehicleModel.odometer = updateObject.odometer
        vehicleModel.year = updateObject.year
        
        try await vehicleModel.update(on: req.db)
        
        let updatedVehicle = DetailObject(id: try vehicleModel.requireID(),
                                          maker: vehicleModel.maker,
                                          model: vehicleModel.model,
                                          year: vehicleModel.year,
                                          odometer: vehicleModel.odometer,
                                          imageKey: vehicleModel.imageKey,
                                          tripHistory: try vehicleModel.tripHistory.map { .init(id: try $0.requireID(), distance: $0.distance, odometer: $0.odometer, destination: $0.destination, createdAt: $0.createdAt, user: .init(id: try $0.user.requireID(), firstName: $0.user.firstName, lastName: $0.user.lastName, imageKey: $0.user.imageKey)) },
                                          createdAt: vehicleModel.createdAt,
                                          updatedAt: vehicleModel.updatedAt,
                                          deletedAt: vehicleModel.deletedAt)
        
        return updatedVehicle
    }
    
    func patchApi(_ req: Request) async throws -> DetailObject {
        let patchObject = try req.content.decode(PatchObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let _ = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        guard let vehicleModel = try await DatabaseModel.query(on: req.db)
            .with(\.$tripHistory)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.vehicleNotFound
        }
        
        // Load user object for every trip history model
        for tripHistory in vehicleModel.tripHistory {
            try await tripHistory.$user.load(on: req.db)
        }
        
        vehicleModel.imageKey = patchObject.imageKey ?? vehicleModel.imageKey
        vehicleModel.maker = patchObject.maker ?? vehicleModel.maker
        vehicleModel.model = patchObject.model ?? vehicleModel.model
        vehicleModel.odometer = patchObject.odometer ?? vehicleModel.odometer
        vehicleModel.year = patchObject.year ?? vehicleModel.year
        
        try await vehicleModel.update(on: req.db)
        
        return .init(id: try vehicleModel.requireID(),
                     maker: vehicleModel.maker,
                     model: vehicleModel.model,
                     year: vehicleModel.year,
                     odometer: vehicleModel.odometer,
                     imageKey: vehicleModel.imageKey,
                     tripHistory: try vehicleModel.tripHistory.map {
            .init(id: try $0.requireID(),
                  distance: $0.distance,
                  odometer: $0.odometer,
                  destination: $0.destination,
                  createdAt: $0.createdAt,
                  user: .init(id: try $0.user.requireID(),
                              firstName: $0.user.firstName,
                              lastName: $0.user.lastName,
                              imageKey: $0.user.imageKey))
        },
                     createdAt: vehicleModel.createdAt,
                     updatedAt: vehicleModel.updatedAt,
                     deletedAt: vehicleModel.deletedAt)
    }
    
    func listApi(_ req: Request) async throws -> [ListObject] {
        let models = try await VehicleModel.query(on: req.db)
            .with(\.$tripHistory)
            .all()
        
        let vehicleModels: [ListObject] = try models.map { vehicleModel in
            return ListObject(id: try vehicleModel.requireID(),
                                maker: vehicleModel.maker,
                                model: vehicleModel.model,
                                year: vehicleModel.year,
                                odometer: vehicleModel.odometer,
                                imageKey: vehicleModel.imageKey)
        }
       
        return vehicleModels
    }
    
    func createNewTrip(_ req: Request) async throws -> Armory.TripHistory.Detail {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let _ = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        let tripInfo = try req.content.decode(Armory.TripHistory.Create.self)
        guard let vehicleId = try? identifier(req) else {
            throw ArmoryErrors.vehicleNotFound
        }
        
        guard let vehicleModel = try await DatabaseModel.query(on: req.db)
            .with(\.$tripHistory)
            .filter(\.$id == vehicleId)
            .first() else {
            throw ArmoryErrors.vehicleNotFound
        }
        
        guard tripInfo.odometer > vehicleModel.odometer else {
            throw ArmoryErrors.vehicleOdometerIsLessThanPrevious
        }
        
        // Create trip history model
        let tripHistoryModel = VehiclesTripHistoryModel(vehicleId: vehicleId, userId: try user.requireID(), odometer: tripInfo.odometer, distance: tripInfo.odometer - vehicleModel.odometer, destination: tripInfo.destination)
        vehicleModel.odometer = tripHistoryModel.odometer
        
        // Update vehicle odometer & save trip history model to database
        try await vehicleModel.update(on: req.db)
        try await tripHistoryModel.save(on: req.db)
        
        let tripHistory = Armory.TripHistory.Detail(id: try tripHistoryModel.requireID(),
                                                    vehicle: .init(id: try vehicleModel.requireID(),
                                                                   maker: vehicleModel.maker,
                                                                   model: vehicleModel.model,
                                                                   year: vehicleModel.year,
                                                                   odometer: vehicleModel.odometer,
                                                                   imageKey: vehicleModel.imageKey),
                                                    distance: tripHistoryModel.distance,
                                                    odometer: tripHistoryModel.odometer,
                                                    destination: tripHistoryModel.destination,
                                                    createdAt: tripHistoryModel.createdAt, user: .init(id: try user.requireID(), firstName: user.firstName, lastName: user.lastName, imageKey: user.imageKey))
        
        return tripHistory
    }
}

