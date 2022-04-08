//
//  WZImageLoader.swift
//  Hafter
//
//  Created by Artur Olar on 08.04.2022.
//

import UIKit

@objc public protocol ImageLoaderProtocol {
    func imageFromUrl(url: URL, completion: @escaping ((UIImage?) -> Void))
}

@objc public class ImageLoader: NSObject, ImageLoaderProtocol {
    
    public override init() {
        URLCache.shared = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: nil)
        super.init()
    }
    
    public func imageFromUrl(url: URL, completion: @escaping ((UIImage?) -> Void)) {
        let request = URLRequest(url: url)
        let cache = URLCache.shared
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let cachedData = cache.cachedResponse(for: request)?.data, let cachedImage = self?.imageFrom(data: cachedData) {
                DispatchQueue.main.async {
                    completion(cachedImage.0)
                }
                return
            }
            
            let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                guard let data = data, let response = response else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                guard let image = self?.imageFrom(data: data) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                let cachedData = CachedURLResponse(response: response, data: image.1)
                cache.storeCachedResponse(cachedData, for: request)
                DispatchQueue.main.async {
                    completion(image.0)
                }
            }
            dataTask.resume()
        }
    }
    
    private func imageFrom(data: Data) -> (UIImage, Data)? {
        
        if let image = UIImage(data: data) {
            return (image, data)
        }
        
        let base64EncodedString = String(decoding: data, as: UTF8.self)
        
        guard let decodedData = Data(base64Encoded: base64EncodedString, options: .ignoreUnknownCharacters) else {
            return nil
        }
        
        guard let decodedImage = UIImage(data: decodedData) else {
            return nil
        }
        return (decodedImage, decodedData)
    }
}
