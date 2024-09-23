//
//  OAuthManager.swift
//  SocialLinkup
//
//  Created by TaeVon Lewis on 9/23/24.
//

import FirebaseFirestore

class OAuthManager {
    let db = Firestore.firestore()

    func fetchCredentials(for platform: String, completion: @escaping (String, String, String, String) -> Void) {
        let docRef = db.collection("OAuthCredentials").document(platform)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let clientId = data?["client_id"] as? String ?? ""
                let clientSecret = data?["client_secret"] as? String ?? ""
                let redirectUrl = data?["redirect_url"] as? String ?? ""
                let callbackUrlScheme = data?["callback_url_scheme"] as? String ?? ""
                completion(clientId, clientSecret, redirectUrl, callbackUrlScheme)
            } else {
                print("Document does not exist: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
