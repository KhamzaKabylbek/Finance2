import UIKit
import PDFKit

extension UIImage {
    func toPDFPage() -> PDFPage? {
        let pdfDocument = PDFDocument()
        let pdfPage = PDFPage(image: self)
        pdfDocument.insert(pdfPage!, at: 0)
        return pdfPage
    }
}
