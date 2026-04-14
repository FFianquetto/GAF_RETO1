//
//  SkinScanRecord.swift
//  HappySkin
//

import Foundation
import UIKit

struct SkinScanRecord: Identifiable {
    let id: String
    let ownerId: String
    let createdAt: Date
    let analysisText: String
    let recommendation: String
    let confidence: Double?
    let imageBase64: String

    var image: UIImage? {
        guard let data = Data(base64Encoded: imageBase64) else { return nil }
        return UIImage(data: data)
    }
}
