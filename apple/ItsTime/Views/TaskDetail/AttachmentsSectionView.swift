import SwiftUI
import SwiftData
import PhotosUI
#if os(iOS)
import UniformTypeIdentifiers
#endif

struct AttachmentsSectionView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showFilePicker = false
    @State private var previewAttachment: TaskAttachment?
    @State private var isLoadingPhoto = false

    private var sortedAttachments: [TaskAttachment] {
        task.attachments.sorted(by: { $0.createdAt < $1.createdAt })
    }

    private var imageAttachments: [TaskAttachment] {
        sortedAttachments.filter(\.isImage)
    }

    private var fileAttachments: [TaskAttachment] {
        sortedAttachments.filter { !$0.isImage }
    }

    var body: some View {
        Section {
            // Add buttons
            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .screenshots])
                ) {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                #if os(iOS)
                Button {
                    showFilePicker = true
                } label: {
                    Label("Files", systemImage: "folder")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                #else
                Button {
                    pickFilesMacOS()
                } label: {
                    Label("Files", systemImage: "folder")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                #endif

                Spacer()

                if isLoadingPhoto {
                    ProgressView()
                }
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("Attachments")
                if !task.attachments.isEmpty {
                    Text("(\(task.attachments.count))")
                        .foregroundStyle(.secondary)
                }
            }
        }

        // Image grid
        if !imageAttachments.isEmpty {
            Section("Images") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(imageAttachments) { attachment in
                        attachmentThumbnail(attachment)
                    }
                }
                .padding(.vertical, 4)
            }
        }

        // File list
        if !fileAttachments.isEmpty {
            Section("Files") {
                ForEach(fileAttachments) { attachment in
                    fileRow(attachment)
                }
                .onDelete { offsets in
                    deleteFiles(at: offsets)
                }
            }
        }

        // Modifiers
        #if os(iOS)
        EmptyView()
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
        #endif

        EmptyView()
            .onChange(of: selectedPhotos) {
                Task { await importPhotos() }
            }
            .sheet(item: $previewAttachment) { attachment in
                AttachmentPreviewView(attachment: attachment)
            }
    }

    // MARK: - Thumbnail

    private func attachmentThumbnail(_ attachment: TaskAttachment) -> some View {
        Button {
            previewAttachment = attachment
        } label: {
            ZStack {
                if let data = attachment.thumbnailData,
                   let image = imageFromData(data) {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.secondary.opacity(0.1)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                Button {
                    deleteAttachment(attachment)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white, .red)
                }
                .offset(x: 6, y: -6)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - File Row

    private func fileRow(_ attachment: TaskAttachment) -> some View {
        Button {
            previewAttachment = attachment
        } label: {
            HStack(spacing: 10) {
                Image(systemName: attachment.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.filename)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(attachment.formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Import Photos

    private func importPhotos() async {
        isLoadingPhoto = true
        defer {
            isLoadingPhoto = false
            selectedPhotos = []
        }

        for item in selectedPhotos {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }

            let filename = "photo_\(Date().timeIntervalSince1970).jpg"
            let mimeType = "image/jpeg"

            guard let path = try? TaskAttachment.saveFile(data: data, filename: filename, taskId: task.id) else { continue }

            // Generate thumbnail
            let thumbnail = generateThumbnail(from: data, maxSize: 200)

            let attachment = TaskAttachment(
                filename: filename,
                mimeType: mimeType,
                fileSize: data.count,
                localPath: path,
                thumbnailData: thumbnail,
                task: task
            )
            modelContext.insert(attachment)
            task.attachments.append(attachment)
        }
        task.updatedAt = Date()
        task.logActivity(action: .fieldChanged, field: "attachments", newValue: "Added \(selectedPhotos.count) photo(s)", context: modelContext)
    }

    // MARK: - Import Files

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard let urls = try? result.get() else { return }

        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else { continue }

            let filename = url.lastPathComponent
            let mimeType = mimeTypeForExtension(url.pathExtension)

            guard let path = try? TaskAttachment.saveFile(data: data, filename: filename, taskId: task.id) else { continue }

            let thumbnail: Data? = mimeType.hasPrefix("image/") ? generateThumbnail(from: data, maxSize: 200) : nil

            let attachment = TaskAttachment(
                filename: filename,
                mimeType: mimeType,
                fileSize: data.count,
                localPath: path,
                thumbnailData: thumbnail,
                task: task
            )
            modelContext.insert(attachment)
            task.attachments.append(attachment)
        }
        task.updatedAt = Date()
        task.logActivity(action: .fieldChanged, field: "attachments", newValue: "Added \(urls.count) file(s)", context: modelContext)
    }

    #if os(macOS)
    private func pickFilesMacOS() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            let result: Result<[URL], Error> = .success(panel.urls)
            handleFileImport(result)
        }
    }
    #endif

    // MARK: - Delete

    private func deleteAttachment(_ attachment: TaskAttachment) {
        attachment.deleteFile()
        modelContext.delete(attachment)
        task.updatedAt = Date()
        task.logActivity(action: .fieldChanged, field: "attachments", newValue: "Removed \(attachment.filename)", context: modelContext)
    }

    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            let attachment = fileAttachments[index]
            deleteAttachment(attachment)
        }
    }

    // MARK: - Helpers

    private func generateThumbnail(from data: Data, maxSize: CGFloat) -> Data? {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnail = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.6)
        #else
        guard let nsImage = NSImage(data: data) else { return nil }
        let scale = min(maxSize / nsImage.size.width, maxSize / nsImage.size.height, 1.0)
        let newSize = CGSize(width: nsImage.size.width * scale, height: nsImage.size.height * scale)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        nsImage.draw(in: CGRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        guard let tiff = newImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.6])
        #endif
    }

    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #else
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #endif
    }

    private func mimeTypeForExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "heic": return "image/heic"
        case "pdf": return "application/pdf"
        case "doc", "docx": return "application/msword"
        case "xls", "xlsx": return "application/vnd.ms-excel"
        case "txt": return "text/plain"
        case "mp4", "mov": return "video/mp4"
        case "mp3", "m4a": return "audio/mpeg"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Attachment Preview

struct AttachmentPreviewView: View {
    let attachment: TaskAttachment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if attachment.isImage, let url = attachment.fileURL,
                   let data = try? Data(contentsOf: url) {
                    imagePreview(data)
                } else if let url = attachment.fileURL {
                    #if os(iOS)
                    QuickLookPreview(url: url)
                    #else
                    VStack(spacing: 16) {
                        Image(systemName: attachment.iconName)
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(attachment.filename)
                            .font(.headline)
                        Text(attachment.formattedSize)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Open in Finder") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    #endif
                } else {
                    ContentUnavailableView("File Not Found", systemImage: "exclamationmark.triangle", description: Text("The attachment file could not be located."))
                }
            }
            .navigationTitle(attachment.filename)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if let url = attachment.fileURL {
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: url)
                    }
                }
            }
        }
    }

    private func imagePreview(_ data: Data) -> some View {
        #if os(iOS)
        if let uiImage = UIImage(data: data) {
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            )
        }
        #else
        if let nsImage = NSImage(data: data) {
            return AnyView(
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            )
        }
        #endif
        return AnyView(EmptyView())
    }
}

#if os(iOS)
import QuickLook

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}
#endif
