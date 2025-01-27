import SwiftUI
import VisionKit
import PDFKit

struct Receipt: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let image: UIImage
}

class ReceiptStore: ObservableObject {
    @Published var receipts: [Receipt] = []
    
    func addReceipt(name: String, image: UIImage) {
        let newReceipt = Receipt(name: name, date: Date(), image: image)
        receipts.insert(newReceipt, at: 0)
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
                                receiptStore.addReceipt(name: receiptName, image: image)
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
