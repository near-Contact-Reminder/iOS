import SwiftUI
import ContactsUI

struct ContactPickerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CNContactPickerViewController

    var onSelect: ([CNContact]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: CNContactPickerViewController,
        context: Context
    ) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: ([CNContact]) -> Void

        init(onSelect: @escaping ([CNContact]) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(
            _ picker: CNContactPickerViewController,
            didSelect contacts: [CNContact]
        ) {
            onSelect(contacts)
        }

        func contactPicker(
            _ picker: CNContactPickerViewController,
            didSelect contact: CNContact
        ) {
            onSelect([contact])
        }
    }
}
