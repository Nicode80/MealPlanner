import Foundation
import SwiftData
import SwiftUI
import UIKit

class DefaultRecipesManager {
    
    static let shared = DefaultRecipesManager()
    
    private init() {}
    
    // Clé pour UserDefaults pour vérifier si l'application a déjà été lancée
    private let isFirstLaunchKey = "isFirstLaunchCompleted"
    
    // Vérifie si c'est le premier lancement
    func isFirstLaunch() -> Bool {
        !UserDefaults.standard.bool(forKey: isFirstLaunchKey)
    }
    
    // Marque le premier lancement comme complété
    func markFirstLaunchCompleted() {
        UserDefaults.standard.set(true, forKey: isFirstLaunchKey)
    }
    
    // Fonction principale pour créer toutes les recettes par défaut
    func createDefaultRecipes(in modelContext: ModelContext) {
        print("Création des recettes par défaut...")
        
        // Créer d'abord tous les articles
        let articles = DefaultArticlesProvider.createAllArticles(in: modelContext)
        
        // Ensuite, créer toutes les recettes
        DefaultRecipesProvider.createAllRecipes(in: modelContext, using: articles)
        
        // Sauvegarder le contexte à la fin
        do {
            try modelContext.save()
            print("Toutes les recettes par défaut ont été créées avec succès")
        } catch {
            print("Erreur lors de la sauvegarde finale des recettes: \(error)")
        }
        
        // Marquer le premier lancement comme complété
        markFirstLaunchCompleted()
    }
    
    // Fonction pour charger une image depuis les assets
    static func loadImageFromAssets(named imageName: String) -> Data? {
        // UIImage.named cherche automatiquement dans les assets
        if let uiImage = UIImage(named: imageName) {
            print("Image \(imageName) chargée avec succès")
            
            // Utiliser l'extension d'optimisation si elle existe
            if let optimizedData = uiImage.optimizedImageData() {
                print("Image optimisée: \(optimizedData.count / 1024) KB")
                return optimizedData
            }
            // Sinon, utiliser le format JPEG avec une compression légère
            else if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                print("Image JPEG: \(jpegData.count / 1024) KB")
                return jpegData
            }
        } else {
            print("Erreur: Impossible de charger l'image \(imageName) depuis les assets")
        }
        return nil
    }
}
