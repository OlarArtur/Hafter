//
//  LocalDataProvider.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import CoreData

protocol LocalDataProviderProtocol {
    func save(movie: HereafterMovie)
    func getMovies(type: HereafterMovieType?) -> [HereafterMovie]
}

final class LocalDataProvider {
    
    private var saveCompletion: (() -> Void)?

    private lazy var persistentContainer: NSPersistentContainer? = {
        guard let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd") else { return nil }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else { return nil }
        let container = NSPersistentContainer(name: "Model", managedObjectModel: managedObjectModel)
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                Swift.print("[DBDataProvider] Failed to load persistent store: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    // MARK: Private
    private func saveContext(completion: (() -> Void)?) {
        guard let context = persistentContainer?.viewContext else { return }
        saveCompletion = completion
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: .NSManagedObjectContextDidSave, object: context)
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                Swift.print("[DBDataProvider] Failed to save context. \(error), \(error.userInfo)")
            }
        }
    }
    
    @objc private func managedObjectContextDidSave() {
        saveCompletion?()
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
}

extension LocalDataProvider: LocalDataProviderProtocol {
    
    func save(movie: HereafterMovie) {
        guard let managedContext = persistentContainer?.viewContext else { return }
        if let hereafterMovieEntity = NSEntityDescription.entity(forEntityName: "DBHereafterMovie", in: managedContext) {
            let hereafterMovieItem = NSManagedObject(entity: hereafterMovieEntity, insertInto: managedContext)
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
            saveContext(completion: nil)
        }
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
                    guard let title = managedData.value(forKey: "title") as? String else { continue }
                    guard let typeString = managedData.value(forKey: "type") as? String, let type = HereafterMovieType(rawValue: typeString) else { continue }
                    guard let adult = managedData.value(forKey: "adult") as? Bool else { continue }
                    guard let originalTitle = managedData.value(forKey: "originalTitle") as? String else { continue }
                    guard let popularity = managedData.value(forKey: "popularity") as? Double else { continue }
                    guard let overview = managedData.value(forKey: "overview") as? String else { continue }
                    guard let originalLanguage = managedData.value(forKey: "originalLanguage") as? String else { continue }
                    let releaseDate = managedData.value(forKey: "releaseDate") as? Date
                    let backdropPath = managedData.value(forKey: "backdropPath") as? String
                    let posterPath = managedData.value(forKey: "posterPath") as? String
                    let movie = Movie(adult: adult,
                                      backdropPath: backdropPath,
                                      originalLanguage: originalLanguage,
                                      title: title,
                                      originalTitle: originalTitle,
                                      overview: overview,
                                      popularity: popularity,
                                      posterPath: posterPath,
                                      releaseDate: releaseDate)
                    let hereafterMovieItem = HereafterMovie(type: type, movie: movie)
                    resultData.append(hereafterMovieItem)
                }
            }
        } catch {
            Swift.print("[DBDataProvider] Failed to fetch favorite items.")
        }
        return resultData
    }
}
