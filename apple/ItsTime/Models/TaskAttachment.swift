import Foundation
import SwiftData

@Model
final class TaskAttachment {
    var id: UUID
    var filename: String
    var mimeType: String
    var fileSize: Int // bytes
    var localPath: String // relative path in app documents
    var thumbnailData: Data? // small preview for images
    var createdAt: Date
    var task: TaskItem?

    init(
        filename: String,
        mimeType: String,
        fileSize: Int,
        localPath: String,
        thumbnailData: Data? = nil,
        task: TaskItem? = nil
    ) {
        self.id = UUID()
        self.filename = filename
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.localPath = localPath
        self.thumbnailData = thumbnailData
        self.createdAt = Date()
        self.task = task
    }

    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }

    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    var iconName: String {
        if isImage { return "photo" }
        if isPDF { return "doc.richtext" }
        if mimeType.hasPrefix("video/") { return "film" }
        if mimeType.hasPrefix("audio/") { return "waveform" }
        if mimeType.hasPrefix("text/") { return "doc.text" }
        return "doc"
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }

    /// Full URL to the file on disk
    var fileURL: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(localPath)
    }

    /// Save data to disk and update localPath
    static func saveFile(data: Data, filename: String, taskId: UUID) throws -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let attachDir = docs.appendingPathComponent("attachments/\(taskId.uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: attachDir, withIntermediateDirectories: true)

        let uniqueName = "\(UUID().uuidString)_\(filename)"
        let fileURL = attachDir.appendingPathComponent(uniqueName)
        try data.write(to: fileURL)
        return "attachments/\(taskId.uuidString)/\(uniqueName)"
    }

    /// Delete the file from disk
    func deleteFile() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
