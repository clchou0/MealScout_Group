import UIKit
import UniformTypeIdentifiers
import MapKit

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []
        print("types:", providers.map { $0.registeredTypeIdentifiers })

        for p in providers {
            for type in [UTType.url, UTType.plainText] where p.hasItemConformingToTypeIdentifier(type.identifier) {
                p.loadItem(forTypeIdentifier: type.identifier) { item, _ in
                    print("SHARED:", item ?? "nil")

                    if let url = item as? URL {
                        Task {
                            await self.saveItemId(url: url)
                        }
                    }

                    DispatchQueue.main.async {
                        self.extensionContext?.completeRequest(returningItems: nil)
                    }
                }
                return
            }
        }
        extensionContext?.completeRequest(returningItems: nil)
    }
    
    func saveItemId (url: URL) async {
        guard let (_, response) = try? await URLSession.shared.data(from: url),
              let finalURL = response.url else {
            print("could not resolve short url")
            return
        }
        print("FINAL URL:", finalURL)

        let items = URLComponents(url: finalURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let raw = items.first(where: { $0.name == "place-id" })?.value else {
            print("no place-id in final url")
            return
        }
        print("RAW ID:", raw)
        UserDefaults(suiteName: "group.MealScout")?.set(raw, forKey: "shared_place_id")
        
        
        let id = UserDefaults(suiteName: "group.MealScout")?.string(forKey: "shared_place_id")
        print("FROM STORE:", id ?? "nil")
    }
    
    func wakeUpMainApp() {
        // A dummy scheme string used purely to wake up the main window
        let dummyScheme = URL(string: "instantopen://")!
        
        // Commands the OS to pull the host app to the foreground
        self.extensionContext?.open(dummyScheme, completionHandler: { success in
            if success {
                print("Host app interface pulled to foreground.")
            }
            
            // Terminate the background extension thread cleanly
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
    }
}
