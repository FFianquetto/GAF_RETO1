//
//  FirestoreSkinScanStore.swift
//  HappySkin
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

enum FirestoreSkinScanError: LocalizedError {
    case imageTooLarge
    case invalidServerResponse

    var errorDescription: String? {
        switch self {
        case .imageTooLarge:
            return "No se pudo optimizar la imagen para guardarla en Firestore."
        case .invalidServerResponse:
            return "Firestore devolvio una respuesta no valida."
        }
    }
}

actor FirestoreSkinScanStore {
    static let shared = FirestoreSkinScanStore()

    private let db: Firestore
    private var shouldBypassIndexedQuery = false

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func saveScan(for user: User, image: UIImage, analysisText: String) async throws {
        let base64Image = try makeCompressedBase64(from: image)
        let payload: [String: Any] = [
            "ownerId": user.uid,
            "createdAt": Timestamp(date: Date()),
            "analysisText": analysisText,
            "recommendation": extractRecommendation(from: analysisText),
            "confidence": extractConfidence(from: analysisText) as Any,
            "imageBase64": base64Image,
        ]

        try await setDocument(
            db.collection("SkinScans").document(),
            data: payload
        )
    }

    func fetchRecentScans(for user: User, limit: Int = 20) async throws -> [SkinScanRecord] {
        let primaryQuery = db.collection("SkinScans")
            .whereField("ownerId", isEqualTo: user.uid)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if shouldBypassIndexedQuery {
            return try await fetchRecentScansFallback(for: user, limit: limit)
        }

        do {
            let snapshot = try await getDocuments(primaryQuery)
            return mapRecords(from: snapshot)
        } catch {
            guard isMissingIndexError(error) else {
                throw error
            }

            shouldBypassIndexedQuery = true
            return try await fetchRecentScansFallback(for: user, limit: limit)
        }
    }

    private func fetchRecentScansFallback(for user: User, limit: Int) async throws -> [SkinScanRecord] {
        // Fallback temporal mientras se crea el indice compuesto en Firebase.
        let fallbackFetchSize = max(limit * 4, 80)
        let fallbackQuery = db.collection("SkinScans")
            .whereField("ownerId", isEqualTo: user.uid)
            .limit(to: fallbackFetchSize)

        let fallbackSnapshot = try await getDocuments(fallbackQuery)
        return mapRecords(from: fallbackSnapshot)
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }

    private func mapRecords(from snapshot: QuerySnapshot) -> [SkinScanRecord] {
        snapshot.documents.compactMap { document in
            let data = document.data()

            guard let ownerId = data["ownerId"] as? String,
                  let createdAtTimestamp = data["createdAt"] as? Timestamp,
                  let analysisText = data["analysisText"] as? String,
                  let recommendation = data["recommendation"] as? String,
                  let imageBase64 = data["imageBase64"] as? String else {
                return nil
            }

            return SkinScanRecord(
                id: document.documentID,
                ownerId: ownerId,
                createdAt: createdAtTimestamp.dateValue(),
                analysisText: analysisText,
                recommendation: recommendation,
                confidence: data["confidence"] as? Double,
                imageBase64: imageBase64
            )
        }
    }

    private func isMissingIndexError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           nsError.code == FirestoreErrorCode.failedPrecondition.rawValue {
            return true
        }

        return nsError.localizedDescription.localizedCaseInsensitiveContains("requires an index")
    }

    private func extractRecommendation(from analysisText: String) -> String {
        let normalized = analysisText.lowercased()
        if normalized.contains("revision profesional sugerida") {
            return "revision profesional sugerida"
        }
        if normalized.contains("seguimiento en dias") {
            return "seguimiento en dias"
        }
        if normalized.contains("monitoreo") {
            return "monitoreo"
        }
        return "monitoreo"
    }

    private func extractConfidence(from analysisText: String) -> Double? {
        let pattern = "Confianza estimada del analisis:\\s*(\\d{1,3})%"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: analysisText.utf16.count)

        guard let match = regex.firstMatch(in: analysisText, range: range),
              let confidenceRange = Range(match.range(at: 1), in: analysisText),
              let confidence = Double(analysisText[confidenceRange]) else {
            return nil
        }

        return max(0, min(confidence, 100))
    }

    private func makeCompressedBase64(from image: UIImage) throws -> String {
        let maxJpegBytes = 430_000
        var workingImage = image
            .normalizedOrientationImage()
            .resizedToFit(maxDimension: 1600)
        var quality: CGFloat = 0.76

        for _ in 0 ..< 28 {
            guard let data = workingImage.jpegData(compressionQuality: quality) else {
                break
            }

            if data.count <= maxJpegBytes {
                return data.base64EncodedString()
            }

            if quality > 0.22 {
                quality -= 0.08
                continue
            }

            let resized = workingImage.resizedBy(scale: 0.80)
            if resized.size.width < 90 || resized.size.height < 90 {
                break
            }

            workingImage = resized
            quality = 0.72
        }

        throw FirestoreSkinScanError.imageTooLarge
    }

    private func getDocuments(_ query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            query.getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    continuation.resume(throwing: FirestoreSkinScanError.invalidServerResponse)
                    return
                }

                continuation.resume(returning: snapshot)
            }
        }
    }

    private func setDocument(_ reference: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: false) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }
}

private extension UIImage {
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension, largestSide > 0 else {
            return self
        }

        let scale = maxDimension / largestSide
        return resizedBy(scale: scale)
    }

    func resizedBy(scale: CGFloat) -> UIImage {
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func normalizedOrientationImage() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
