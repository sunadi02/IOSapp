//
//  LinkExtractor.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//finds web links inside a message, including ones typed without http
enum LinkExtractor {

    static let maxLinks = 5

    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    //where links sit in the text, so their words are not mistaken for message wording
    static func ranges(in text: String) -> [Range<String.Index>] {
        guard let detector else { return [] }
        return detector
            .matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text) }
    }

    static func links(in text: String) -> [URL] {
        guard let detector else { return [] }

        var seen = Set<String>()
        var links: [URL] = []

        for match in detector.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            //the detector would add http to a bare domain, so the typed text is normalised instead
            guard match.url?.scheme?.lowercased() != "mailto",
                  let matched = Range(match.range, in: text),
                  let url = URLAnalyzer.normalize(String(text[matched])),
                  seen.insert(url.absoluteString).inserted else { continue }

            links.append(url)
            if links.count == maxLinks { break }
        }
        return links
    }
}
