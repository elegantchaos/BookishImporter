// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import ISBN
import Logger

let deliciousChannel = Channel("DeliciousImporter")

extension Dictionary {
    func nonZeroDouble(forKey key: Key) -> Double? {
        guard let value = self[key] as? Double, value != 0 else { return nil }
        return value
    }
}


public class DeliciousLibraryImporter: Importer {
    override class public var identifier: String { return "com.elegantchaos.bookish.importer.delicious-library" }

    public init(manager: ImportManager) {
        super.init(name: "Delicious Library", source: .userSpecifiedFile, manager: manager)
    }
    
    override func makeSession(importing url: URL, monitor: ImportMonitor?) -> URLImportSession? {
        return DeliciousLibraryImportSession(importer: self, url: url, monitor: monitor)
    }

    public override var fileTypes: [String]? {
        return ["xml"]
    }
}

public class DeliciousLibraryImportSession: URLImportSession {
    public struct Book {
        public let id: String
        public let title: String
        public let subtitle: String?
        public let isbn: String?
        public let asin: String?
        public let format: String?
        
        public let classification: String?
        
        public let added: Date?
        public let modified: Date?
        public let published: Date?
        
        public let height: Double?
        public let width: Double?
        public let length: Double?
        
        public let raw: [String:Any]
        public let images: [URL]
        
        init?(from record: [String:Any], info: Validated) {
            deliciousChannel.log("Started import")
            
            if let uuid = record["uuidString"] as? String {
                id = uuid
            } else if let uuid = record["foreignUUIDString"] as? String {
                id = uuid
            } else {
                id = "delicious-import-\(info.title)"
            }
            
            title = info.title
            subtitle = record["subtitle"] as? String
            
            if let ean = record["ean"] as? String, ean.isISBN13 {
                isbn = ean
            } else if let value = record["isbn"] as? String {
                let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                isbn = trimmed.isbn10to13
            } else {
                isbn = nil
            }
            
            height = record.nonZeroDouble(forKey: "boxHeightInInches")
            width = record.nonZeroDouble(forKey: "boxWidthInInches")
            length = record.nonZeroDouble(forKey: "boxLengthInInches")
            
            asin = record["asin"] as? String
            classification = record["deweyDecimal"] as? String
            
            added = record["creationDate"] as? Date
            modified = record["lastModificationDate"] as? Date
            published = record["publishDate"] as? Date
            
            raw = record
            self.format = info.format
            
            var urls: [URL] = []
            for key in ["coverImageLargeURLString", "coverImageMediumURLString", "coverImageSmallURLString"] {
                if let string = record[key] as? String, let url = URL(string: string) {
                    urls.append(url)
                }
            }
            images = urls

            //                process(creators: creators, for: book)
            //
            //                if let publishers = record["publishersCompositeString"] as? String, !publishers.isEmpty {
            //                    process(publishers: publishers, for: book)
            //                }
            //
            //                if let series = record["seriesSingularString"] as? String, !series.isEmpty {
            //                    process(series: series, position: 0, for: book)
            //                }
        }
    }
    
    typealias Record = [String:Any]
    typealias RecordList = [Record]
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame", "DVD"]
    
    let list: RecordList

    override init?(importer: Importer, url: URL, monitor: ImportMonitor?) {
        // check we can parse the xml
        guard let data = try? Data(contentsOf: url), let list = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? RecordList else {
            return nil
        }
        
        // check that the records look to be in the right format
        guard let record = list.first, let _ = record["actorsCompositeString"] as? String else {
            return nil
        }
        
        self.list = list
        super.init(importer: importer, url: url, monitor: monitor)
    }
    
    struct Validated {
        let format: String?
        let title: String
        let creators: String
    }
    
    func validate(_ record: Record) -> Validated? {
        let format = record["formatSingularString"] as? String
        guard format == nil || !formatsToSkip.contains(format!) else { return nil }
        let type = record["type"] as? String
        guard type == nil || !formatsToSkip.contains(type!) else { return nil }
        guard let title = record["title"] as? String, let creators = record["creatorsCompositeString"] as? String else { return nil }
        
        return Validated(format: format, title: title, creators: creators)
    }
    
    override func run() {
        let monitor = self.monitor
        monitor?.session(self, willImportItems: list.count)
        for record in list {
            if let info = self.validate(record) {
                if let book = Book(from: record, info: info) {
                    monitor?.session(self, didImport: book)
                } else {
                    deliciousChannel.log("failed to make book from \(record)")
                }
            } else {
                deliciousChannel.log("skipped non-book \(record["title"] ?? record)")
            }
        }
        monitor?.sessionDidFinish(self)
    }
    
    //
    //private func process(creators: String, for book: Book) {
    //    var index = 1
    //    for creator in creators.split(separator: "\n") {
    //        let trimmed = creator.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    //        if trimmed != "" {
    //            let author: Person
    //            if let cached = cachedPeople[trimmed] {
    //                author = cached
    //            } else {
    //                author = Person.named(trimmed, in: context)
    //                if author.source == nil {
    //                    author.source = DeliciousLibraryImporter.identifier
    //                    author.uuid = "\(book.uuid!)-author-\(index)"
    //                }
    //                index += 1
    //                cachedPeople[trimmed] = author
    //            }
    //            let relationship = author.relationship(as: Role.StandardName.author)
    //            relationship.add(book)
    //        }
    //    }
    //}
    
    //private func process(publishers: String, for book: Book) {
    //    for publisher in publishers.split(separator: "\n") {
    //        let trimmed = publisher.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    //        if trimmed != "" {
    //            let publisher: Publisher
    //            if let cached = cachedPublishers[trimmed] {
    //                publisher = cached
    //            } else {
    //                publisher = Publisher.named(trimmed, in: context)
    //                if publisher.source == nil {
    //                    publisher.source = DeliciousLibraryImporter.identifier
    //                }
    //                cachedPublishers[trimmed] = publisher
    //            }
    //            publisher.add(book)
    //        }
    //    }
    //}
    //
    //private func process(series: String, position: Int, for book: Book) {
    //    let trimmed = series.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    //    if trimmed != "" {
    //        let series: Series
    //        if let cached = cachedSeries[trimmed] {
    //            series = cached
    //        } else {
    //            series = Series.named(trimmed, in: context)
    //            if series.source == nil {
    //                series.source = DeliciousLibraryImporter.identifier
    //            }
    //            cachedSeries[trimmed] = series
    //        }
    //        let entry = SeriesEntry(context: context)
    //        entry.book = book
    //        entry.series = series
    //        if position != 0 {
    //            entry.position = Int16(position)
    //        }
    //    }
    //}
    
}

