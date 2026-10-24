//
//  ScamClassifier.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import CoreML
import NaturalLanguage

//protocol so the message scanner can be tested without the trained model
protocol ScamClassifying {
    //how likely the message is a scam from 0 to 1, nil when the model is not installed
    func scamProbability(for text: String) -> Double?
}

//runs the Create ML text model on the device, nothing about the message is sent anywhere
struct ScamClassifier: ScamClassifying {

    static let modelName = "ScamTextClassifier"
    static let scamLabel = "scam"
    static let strongFrom = 0.9
    static let likelyFrom = 0.75

    static let shared = ScamClassifier()

    private let model: NLModel?

    init(bundle: Bundle = .main) {
        model = Self.loadModel(from: bundle)
    }

    var isAvailable: Bool {
        model != nil
    }

    func scamProbability(for text: String) -> Double? {
        guard let model else { return nil }
        return model.predictedLabelHypotheses(for: text, maximumCount: 2)[Self.scamLabel] ?? 0
    }

    //a high score is a strong hint, a middling one only a mild one, and a low one says nothing
    static func signal(for probability: Double) -> RiskSignal? {
        let percent = Int((probability * 100).rounded())

        if probability >= strongFrom {
            return RiskSignal(
                title: "Matches known scam messages",
                detail: "The on-device model found this message very similar to scam messages it learned from (\(percent)% sure).",
                weight: 30
            )
        }
        if probability >= likelyFrom {
            return RiskSignal(
                title: "Similar to scam messages",
                detail: "The on-device model found this message somewhat similar to scam messages it learned from (\(percent)% sure).",
                weight: 15
            )
        }
        return nil
    }

    private static func loadModel(from bundle: Bundle) -> NLModel? {
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc"),
              let mlModel = try? MLModel(contentsOf: url) else {
            return nil
        }
        return try? NLModel(mlModel: mlModel)
    }
}
