//
//  LocalDataProvider.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import CoreData

protocol LocalDataProviderProtocol {
    func save(movie: HereafterMovie, completion: ((Bool) -> Void)?)
    func getMovies(type: HereafterMovieType?) -> [HereafterMovie]
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void)
    func getTags(movieId: String) -> [String]
    func updateTags(movieId: String, tags: [String], completion: @escaping (Bool) -> Void)
}

final class LocalDataProvider {
    
    private var saveCompletion: ((Bool) -> Void)?

    private lazy var persistentContainer: NSPersistentContainer? = {
        guard let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd") else { return nil }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else { return nil }
        let container = NSPersistentContainer(name: "Model", managedObjectModel: managedObjectModel)
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                Swift.print("[DBDataProvider] Failed to load persistent store: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    // MARK: Private

    /// Returns true only when the compiled Core Data model already contains the `tags` attribute.
    /// Guards against crashes when running with the old schema before a proper model migration.
    private var modelHasTags: Bool { modelHas("tags") }

    private func modelHas(_ name: String) -> Bool {
        persistentContainer?
            .viewContext
            .persistentStoreCoordinator?
            .managedObjectModel
            .entitiesByName["DBHereafterMovie"]?
            .attributesByName[name] != nil
    }

    private func saveContext(completion: ((Bool) -> Void)?) {
        guard let context = persistentContainer?.viewContext else {
            completion?(false)
            return
        }
        guard context.hasChanges else {
            completion?(true)
            return
        }
        saveCompletion = completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: context
        )
        do {
            try context.save()
        } catch let error as NSError {
            NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextDidSave, object: context)
            saveCompletion?(false)
            saveCompletion = nil
            Swift.print("[DBDataProvider] Failed to save context. \(error), \(error.userInfo)")
        }
    }
    
    @objc private func managedObjectContextDidSave() {
        saveCompletion?(true)
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
}

extension LocalDataProvider: LocalDataProviderProtocol {
    
    func save(movie: HereafterMovie, completion: ((Bool) -> Void)?) {
        guard let managedContext = persistentContainer?.viewContext else {
            completion?(false)
            return
        }
        // Deduplication: if a movie with the same TMDb id already exists, update its tier instead
        let dedupeRequest = DBHereafterMovie.fetchRequest()
        dedupeRequest.predicate = NSPredicate(format: "id = %@", movie.movie.id)
        if let existing = try? managedContext.fetch(dedupeRequest), let existing = existing.first {
            existing.setValue(movie.type.rawValue, forKey: "type")
            saveContext(completion: completion)
            return
        }
        guard let hereafterMovieEntity = NSEntityDescription.entity(forEntityName: "DBHereafterMovie", in: managedContext) else {
            completion?(false)
            return
        }
        let hereafterMovieItem = NSManagedObject(entity: hereafterMovieEntity, insertInto: managedContext)
        hereafterMovieItem.setValue(movie.movie.id, forKey: "id")
        hereafterMovieItem.setValue(movie.type.rawValue, forKey: "type")
        hereafterMovieItem.setValue(movie.movie.title, forKey: "title")
        hereafterMovieItem.setValue(movie.movie.originalTitle, forKey: "originalTitle")
        hereafterMovieItem.setValue(movie.movie.adult, forKey: "adult")
        hereafterMovieItem.setValue(movie.movie.backdropPath, forKey: "backdropPath")
        hereafterMovieItem.setValue(movie.movie.originalLanguage, forKey: "originalLanguage")
        hereafterMovieItem.setValue(movie.movie.overview, forKey: "overview")
        hereafterMovieItem.setValue(movie.movie.popularity, forKey: "popularity")
        hereafterMovieItem.setValue(movie.movie.posterPath, forKey: "posterPath")
        hereafterMovieItem.setValue(movie.movie.releaseDate, forKey: "releaseDate")
        if modelHasTags {
            hereafterMovieItem.setValue(movie.tags.joined(separator: ","), forKey: "tags")
        }
        if modelHas("rating") {
            hereafterMovieItem.setValue(movie.rating, forKey: "rating")
        }
        if modelHas("watchedDate") {
            hereafterMovieItem.setValue(movie.watchedDate, forKey: "watchedDate")
        }
        saveContext(completion: completion)
    }

    func getMovies(type: HereafterMovieType?) -> [HereafterMovie] {
        guard let managedContext = persistentContainer?.viewContext else { return [] }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DBHereafterMovie")
        if let type = type {
            fetchRequest.predicate = NSPredicate(format: "type = %@", type.rawValue)
        }
        var resultData: [HereafterMovie] = []
        do {
            let result = try managedContext.fetch(fetchRequest)
            for data in result {
                if let managedData = data as? NSManagedObject {
                    guard let id = managedData.value(forKey: "id") as? String else { continue }
                    guard let title = managedData.value(forKey: "title") as? String else { continue }
                    guard let typeString = managedData.value(forKey: "type") as? String,
                          let type = HereafterMovieType(rawValue: typeString) else { continue }
                    guard let adult = managedData.value(forKey: "adult") as? Bool else { continue }
                    guard let originalTitle = managedData.value(forKey: "originalTitle") as? String else { continue }
                    guard let popularity = managedData.value(forKey: "popularity") as? Double else { continue }
                    guard let overview = managedData.value(forKey: "overview") as? String else { continue }
                    guard let originalLanguage = managedData.value(forKey: "originalLanguage") as? String else { continue }
                    let releaseDate = managedData.value(forKey: "releaseDate") as? Date
                    let backdropPath = managedData.value(forKey: "backdropPath") as? String
                    let posterPath = managedData.value(forKey: "posterPath") as? String
                    let tagsString = modelHas("tags") ? (managedData.value(forKey: "tags") as? String ?? "") : ""
                    let ratingNumber = modelHas("rating") ? (managedData.value(forKey: "rating") as? NSNumber) : nil
                    let rating = (ratingNumber?.intValue ?? 0) > 0 ? ratingNumber?.intValue : nil
                    let watchedDate = modelHas("watchedDate") ? (managedData.value(forKey: "watchedDate") as? Date) : nil
                    let movie = Movie(id: id,
                                      adult: adult,
                                      backdropPath: backdropPath,
                                      originalLanguage: originalLanguage,
                                      title: title,
                                      originalTitle: originalTitle,
                                      overview: overview,
                                      popularity: popularity,
                                      posterPath: posterPath,
                                      releaseDate: releaseDate)
                    let hereafterMovieItem = HereafterMovie(type: type, movie: movie, rating: rating, watchedDate: watchedDate)
                    hereafterMovieItem.tags = Self.parseTags(tagsString)
                    resultData.append(hereafterMovieItem)
                }
            }
        } catch {
            Swift.print("[DataProvider] Failed to fetch items.")
        }
        return resultData
    }

    func getTags(movieId: String) -> [String] {
        guard modelHasTags,
              let managedContext = persistentContainer?.viewContext else { return [] }
        let fetchRequest = DBHereafterMovie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", movieId)
        do {
            let results = try managedContext.fetch(fetchRequest)
            let tagsString = results.first?.value(forKey: "tags") as? String ?? ""
            return Self.parseTags(tagsString)
        } catch {
            return []
        }
    }

    func updateTags(movieId: String, tags: [String], completion: @escaping (Bool) -> Void) {
        guard modelHasTags,
              let managedContext = persistentContainer?.viewContext else {
            completion(false)
            return
        }
        let fetchRequest = DBHereafterMovie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", movieId)
        do {
            let results = try managedContext.fetch(fetchRequest)
            guard let movie = results.first else {
                completion(false)
                return
            }
            movie.setValue(tags.joined(separator: ","), forKey: "tags")
            saveContext(completion: completion)
        } catch {
            Swift.print("[DataProvider] Failed to update tags.")
            completion(false)
        }
    }

    private static func parseTags(_ string: String) -> [String] {
        return string
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        guard let managedContext = persistentContainer?.viewContext else {
            completion(false)
            return
        }
        let fetchRequest = DBHereafterMovie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", movie.movie.id)
        do {
            let movieObjects = try managedContext.fetch(fetchRequest)
            if movieObjects.isEmpty {
                save(movie: movie, completion: completion)
            } else {
                let managedObject = movieObjects[0]
                managedObject.setValue(movie.type.rawValue, forKey: "type")
                if modelHas("rating") { managedObject.setValue(movie.rating, forKey: "rating") }
                if modelHas("watchedDate") { managedObject.setValue(movie.watchedDate, forKey: "watchedDate") }
                saveContext(completion: completion)
            }
        } catch {
            Swift.print("[DataProvider] Failed to fetch items.")
            completion(false)
        }
    }
}
