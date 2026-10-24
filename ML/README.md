# Scam message classifier

ScamShield uses a small text classifier to judge whether a message looks like a scam. It runs fully on the device through Natural Language and Core ML, so message text is never sent to a cloud AI service.

This folder holds the training data and the script that builds the model. It is not part of the app target and is never shipped inside the app.

## Files

| File | What it is |
|---|---|
| `Data/sms_spam_collection.csv` | Public SMS messages, converted from the UCI SMS Spam Collection (see below) |
| `Data/local_messages.csv` | About 180 hand written examples: Sri Lankan bank, OTP, delivery, SIM and prize scams, and genuine bank, OTP and delivery messages |
| `train.swift` | Trains the model with Create ML and writes `ScamShield/ML/ScamTextClassifier.mlmodel` |

Both CSV files have the columns `text,label`, where the label is `scam` or `safe`.

## Train the model (macOS with Xcode)

Run this from the project root:

```
swift ML/train.swift
```

It prints the accuracy on messages held back from training, a few sample predictions, and writes the model to `ScamShield/ML/ScamTextClassifier.mlmodel`. Xcode compiles that file into the app automatically because it sits inside the app folder.

If the script cannot import Create ML, the same result is possible with the Create ML app (Xcode, Open Developer Tool, Create ML): choose Text Classifier, use `Data/sms_spam_collection.csv` as training data with `text` and `label` as the columns, and export the model as `ScamTextClassifier.mlmodel`.

## How the app uses it

`ScamClassifier` (in `ScamShield/Services/Analysis`) loads `ScamTextClassifier` from the app bundle when the app starts and asks it how likely a scanned message is a scam. The answer becomes one more reason on the result screen: a score of 90% or more adds a strong warning, 75% to 90% a mild one, and anything lower says nothing. If the model file is missing the app still works and simply skips this step. Settings, in debug builds, shows whether the model is loaded.

## Data sources and credit

**Public data.** `Data/sms_spam_collection.csv` comes from the SMS Spam Collection v.1 on the UCI Machine Learning Repository, licensed under Creative Commons Attribution 4.0 (CC BY 4.0).

- Almeida, T.A., Gomez Hidalgo, J.M., Yamakami, A. (2011). *Contributions to the study of SMS spam filtering: new collection and results.* Proceedings of the 2011 ACM Symposium on Document Engineering (DocEng '11), Mountain View, CA, USA.
- Dataset: https://archive.ics.uci.edu/dataset/228/sms+spam+collection (DOI 10.24432/C5CC84)

Changes made for this project: converted to CSV, labels renamed (`spam` to `scam`, `ham` to `safe`), HTML character codes decoded, repeated messages removed. That leaves 642 scam and 4,517 safe messages.

**Local data.** `Data/local_messages.csv` was written by the author for this project. The phone numbers and web addresses in it are made up.

## Known limits

- The public set is mostly UK and Singapore messages from around 2010, so the local examples are repeated during training to pull the model towards the scams people in Sri Lanka actually receive.
- It reads English only. Sinhala and Tamil messages are reported as not fully checked.
- A classifier gives a probability, not proof. ScamShield treats it as one signal next to the wording rules and the link checks.
