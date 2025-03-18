import SwiftUI
import VisionKit
import Vision
import PDFKit

struct Receipt: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let image: UIImage
    let extractedText: String
    let extractedAmount: Double?
    let extractedDate: Date?
    let category: Category?
}

class ReceiptStore: ObservableObject {
    @Published var receipts: [Receipt] = []
    
    func addReceipt(name: String, image: UIImage, extractedText: String, amount: Double?, date: Date?, category: Category?) {
        let newReceipt = Receipt(name: name, date: Date(), image: image, 
                               extractedText: extractedText, 
                               extractedAmount: amount,
                               extractedDate: date,
                               category: category)
        receipts.insert(newReceipt, at: 0)
    }
    
    func exportToPDF() -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Finance App",
            kCGPDFContextAuthor: "User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            for (index, receipt) in receipts.enumerated() {
                context.beginPage()
                
                let titleText = NSAttributedString(
                    string: "Чек #\(index + 1): \(receipt.name)",
                    attributes: [.font: UIFont.boldSystemFont(ofSize: 16)]
                )
                titleText.draw(at: CGPoint(x: 50, y: 50))
                
                let imageRect = CGRect(x: 50, y: 100, width: 495, height: 600)
                receipt.image.draw(in: imageRect)
            }
        }
    }
}

struct ReceiptScannerView: View {
    @StateObject private var receiptStore = ReceiptStore()
    @State private var showingScanner = false
    @State private var showingNameInput = false
    @State private var tempImage: UIImage?
    @State private var receiptName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var processingReceipt = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Scan button section
                        Button(action: {
                            if VNDocumentCameraViewController.isSupported {
                                showingScanner = true
                            } else {
                                errorMessage = "Сканер недоступен на этом устройстве"
                                showingError = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.viewfinder")
                                    .font(.title2)
                                Text("Сканировать чек")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Receipts list
                        if receiptStore.receipts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.viewfinder")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text("Нет сканированных чеков")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(receiptStore.receipts) { receipt in
                                    ReceiptRow(receipt: receipt)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Чеки")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportReceipts) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView { images in
                    if let firstImage = images.first {
                        tempImage = firstImage
                        showingNameInput = true
                    }
                }
            }
            .sheet(isPresented: $showingNameInput) {
                NavigationView {
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            if let image = tempImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .padding()
                            }
                            
                            TextField("Название чека", text: $receiptName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }
                    }
                    .navigationTitle("Добавить чек")
                    .navigationBarItems(
                        leading: Button("Отмена") {
                            showingNameInput = false
                            tempImage = nil
                            receiptName = ""
                        },
                        trailing: Button("Сохранить") {
                            if let image = tempImage {
                                processReceipt(image: image)
                            }
                            showingNameInput = false
                            tempImage = nil
                            receiptName = ""
                        }
                        .disabled(receiptName.isEmpty)
                    )
                }
            }
        }
    }
    
    private func processReceipt(image: UIImage) {
        processingReceipt = true
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let extractedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            // Extract amount using regex
            let amountPattern = #"(?:сумма|итого|total):?\s*(\d+[.,]\d{2})"#
            var extractedAmount: Double?
            
            if let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: extractedText.utf16.count)
                if let match = amountRegex.firstMatch(in: extractedText, range: range),
                   let matchRange = Range(match.range(at: 1), in: extractedText) {
                    let amountString = String(extractedText[matchRange])
                    extractedAmount = Double(amountString.replacingOccurrences(of: ",", with: "."))
                }
            }
            
            // Extract date using correct NSTextCheckingTypes
            let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let dateRange = NSRange(location: 0, length: extractedText.utf16.count)
            let extractedDate = dateDetector?.firstMatch(in: extractedText, range: dateRange)?.date
            
            // Categorize receipt
            let category = categorizeReceipt(text: extractedText)
            
            DispatchQueue.main.async {
                self.receiptStore.addReceipt(
                    name: self.receiptName,
                    image: image,
                    extractedText: extractedText,
                    amount: extractedAmount,
                    date: extractedDate,
                    category: category
                )
                self.processingReceipt = false
            }
        }
        
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    private func categorizeReceipt(text: String) -> Category? {
        let categoryKeywords: [Category: Set<String>] = [
            Category(id: UUID(), name: "Продукты", icon: "cart", color: "4CAF50", type: .expense): ["продукты", "еда", "магазин"],
            Category(id: UUID(), name: "Транспорт", icon: "car", color: "2196F3", type: .expense): ["такси", "метро", "автобус"],
            Category(id: UUID(), name: "Развлечения", icon: "film", color: "9C27B0", type: .expense): ["кино", "театр", "концерт"]
        ]
        
        let lowercasedText = text.lowercased()
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { lowercasedText.contains($0) }) {
                return category
            }
        }
        return nil
    }
    
    private func exportReceipts() {
        guard let pdfData = receiptStore.exportToPDF() else { return }
        let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct ReceiptRow: View {
    let receipt: Receipt

    var body: some View {
        NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(receipt.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                Image(uiImage: receipt.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct ReceiptDetailView: View {
    let receipt: Receipt

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(receipt.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Image(uiImage: receipt.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 500)
                    .cornerRadius(12)
                    .padding()
            }
            .padding()
        }
        .navigationTitle("Детали чека")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DocumentScannerView: UIViewControllerRepresentable {
    let completion: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: ([UIImage]) -> Void
        
        init(completion: @escaping ([UIImage]) -> Void) {
            self.completion = completion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedPages: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                scannedPages.append(image)
            }
            
            controller.dismiss(animated: true) {
                self.completion(scannedPages)
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
    }
}

//#Preview {
//    ReceiptScannerView()
//}
