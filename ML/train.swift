//
//  train.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//
//  Trains the on-device scam message classifier with Create ML.
//  Run from the project root on a Mac:  swift ML/train.swift
//

import CreateML
import Foundation
import NaturalLanguage

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let generalURL = root.appendingPathComponent("ML/Data/sms_spam_collection.csv")
let localURL = root.appendingPathComponent("ML/Data/local_messages.csv")
let modelURL = root.appendingPathComponent("ScamShield/ML/ScamTextClassifier.mlmodel")

//the hand written Sri Lankan examples are few, so they are repeated to carry weight next to the big public set
let localRepeats = 5

let general = try MLDataTable(contentsOf: generalURL)
let local = try MLDataTable(contentsOf: localURL)
print("Public messages: \(general.rows.count), local messages: \(local.rows.count)")

let (generalTrain, generalTest) = general.randomSplit(by: 0.8, seed: 7)
let (localTrain, localTest) = local.randomSplit(by: 0.8, seed: 7)

var training = generalTrain
for _ in 0..<localRepeats {
    training.append(contentsOf: localTrain)
}

let parameters = MLTextClassifier.ModelParameters(language: .english)
let classifier = try MLTextClassifier(
    trainingData: training,
    textColumn: "text",
    labelColumn: "label",
    parameters: parameters
)

func report(_ title: String, on table: MLDataTable) {
    let metrics = classifier.evaluation(on: table, textColumn: "text", labelColumn: "label")
    let accuracy = (1 - metrics.classificationError) * 100
    print("\(title): \(String(format: "%.1f", accuracy))% correct on \(table.rows.count) messages")
    print(metrics.confusion)
}

report("Held back public messages", on: generalTest)
report("Held back local messages", on: localTest)

let samples = [
    "Dear customer, your account is suspended. Verify your details now at http://bank-verify.xyz",
    "Please share the OTP you received so we can refund your money",
    "Your OTP is 482913. Do not share it with anyone.",
    "Are we still meeting for lunch tomorrow?"
]
for sample in samples {
    print("\(try classifier.prediction(from: sample)): \(sample)")
}

let metadata = MLModelMetadata(
    author: "M.S.A.A. Sunadi Amarasinghe",
    shortDescription: "Says whether a text message looks like a scam or is safe. Trained on the UCI SMS Spam Collection and hand written Sri Lankan examples.",
    version: "1.0"
)
try FileManager.default.createDirectory(at: modelURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try classifier.write(to: modelURL, metadata: metadata)
print("Saved model to \(modelURL.path)")
