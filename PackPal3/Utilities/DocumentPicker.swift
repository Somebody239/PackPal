//
//  DocumentPicker.swift
//  PackPal3
//
//  Created by AI Assistant on 2025-10-02.
//  Document picker for adding photos and files to trips
//

import UIKit
import UniformTypeIdentifiers

// MARK: - DocumentPicker

/// Document picker for adding photos and files to trips
final class DocumentPicker: NSObject, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties
    
    private weak var presenter: UIViewController?
    var onPick: ((URL) -> Void)?

    // MARK: - Initialization
    
    init(presenter: UIViewController) { self.presenter = presenter }

    // MARK: - Public Methods
    
    func present() {
        let menu = UIAlertController(title: "Add Document", message: nil, preferredStyle: .actionSheet)
        menu.addAction(UIAlertAction(title: "Photo", style: .default) { _ in self.pickPhoto() })
        menu.addAction(UIAlertAction(title: "File", style: .default) { _ in self.pickFile() })
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presenter?.present(menu, animated: true)
    }

    // MARK: - Private Methods
    
    private func pickPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        presenter?.present(imagePicker, animated: true)
    }

    private func pickFile() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }

    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        onPick?(url)
    }
}

