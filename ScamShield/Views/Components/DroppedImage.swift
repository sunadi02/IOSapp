//
//  DroppedImage.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI
import UniformTypeIdentifiers

//an image dragged in from Photos or Files, anything else that is dropped is ignored
nonisolated struct DroppedImage: Transferable {

    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            DroppedImage(data: data)
        }
    }
}
