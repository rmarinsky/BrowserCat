import AppKit
import os

actor FaviconManager {
    static let shared = FaviconManager()

    private let memoryCache = NSCache<NSString, NSImage>()
    private let fileManager = FileManager.default
    private var inFlight: [String: Task<NSImage?, Never>] = [:]

    private var cacheDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("BrowserCat/favicons")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func favicon(for domain: String) async -> NSImage? {
        let key = domain.lowercased() as NSString

        // 1. Memory cache
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        // 2. Disk cache
        let diskURL = cacheDir.appendingPathComponent("\(key).png")
        if let data = try? Data(contentsOf: diskURL), let image = NSImage(data: data) {
            memoryCache.setObject(image, forKey: key)
            return image
        }

        // 3. Deduplicate in-flight requests
        if let existing = inFlight[domain as String] {
            return await existing.value
        }

        let task = Task<NSImage?, Never> {
            await fetchAndCache(domain: domain as String, key: key, diskURL: diskURL)
        }
        inFlight[domain as String] = task
        let result = await task.value
        inFlight[domain as String] = nil
        return result
    }

    private func fetchAndCache(domain: String, key: NSString, diskURL: URL) async -> NSImage? {
        guard let url = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=32") else {
            return nil
        }

        do {
            let request = URLRequest(url: url, timeoutInterval: 5)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = NSImage(data: data)
            else { return nil }

            // Save to disk
            if let tiff = image.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: diskURL, options: .atomic)
            }

            memoryCache.setObject(image, forKey: key)
            return image
        } catch {
            Log.app.debug("Favicon fetch failed for \(domain): \(error.localizedDescription)")
            return nil
        }
    }
}
