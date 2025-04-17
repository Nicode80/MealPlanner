import Foundation
import SwiftData
import UIKit

/// Classe utilitaire contenant des fonctions communes pour la manipulation des recettes
class RecipeUtilities {
    
    /// Charge une image à partir des assets et l'optimise
    /// - Parameter imageName: Nom de l'image dans les assets
    /// - Returns: Données optimisées de l'image, ou nil si l'image n'est pas trouvée
    static func loadOptimizedImageFromAssets(named imageName: String) -> Data? {
        // UIImage.named cherche automatiquement dans les assets
        if let uiImage = UIImage(named: imageName) {
            print("Image '\(imageName)' chargée avec succès")
            
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
            print("Erreur: Impossible de charger l'image '\(imageName)' depuis les assets")
        }
        return nil
    }
    
    /// Crée un article (ingrédient)
    /// - Parameters:
    ///   - name: Nom de l'article
    ///   - category: Catégorie (rayon) de l'article
    ///   - unit: Unité de mesure
    ///   - modelContext: Contexte SwiftData
    /// - Returns: L'article créé
    static func createArticle(name: String, category: String, unit: String, in modelContext: ModelContext) -> Article {
        let article = Article(name: name, category: category, unit: unit, isFood: true)
        modelContext.insert(article)
        return article
    }
    
    /// Crée un ingrédient (RecipeArticle) pour une recette
    /// - Parameters:
    ///   - recipe: Recette à laquelle ajouter l'ingrédient
    ///   - article: Article (ingrédient)
    ///   - quantity: Quantité pour une personne
    ///   - isOptional: Indique si l'ingrédient est optionnel
    ///   - modelContext: Contexte SwiftData
    /// - Returns: L'ingrédient créé
    static func createIngredient(for recipe: Recipe, article: Article, quantity: Double, isOptional: Bool = false, in modelContext: ModelContext) -> RecipeArticle {
        let ingredient = RecipeArticle(recipe: recipe, article: article, quantity: quantity, isOptional: isOptional)
        modelContext.insert(ingredient)
        return ingredient
    }
    
    /// Crée une recette avec tous ses composants
    /// - Parameters:
    ///   - name: Nom de la recette
    ///   - details: Description de la recette
    ///   - imageName: Nom de l'image dans les assets
    ///   - ingredients: Liste des ingrédients avec leurs quantités
    ///   - modelContext: Contexte SwiftData
    /// - Returns: La recette créée
    static func createCompleteRecipe(
        name: String,
        details: String,
        imageName: String,
        ingredients: [(article: Article, quantity: Double, isOptional: Bool)],
        in modelContext: ModelContext
    ) -> Recipe? {
        // Charger l'image
        let photoData = loadOptimizedImageFromAssets(named: imageName)
        
        // Créer la recette
        let recipe = Recipe(
            name: name,
            details: details,
            photo: photoData
        )
        
        // Ajouter la recette au contexte
        modelContext.insert(recipe)
        
        // Créer les ingrédients
        let recipeIngredients = ingredients.map { ingredient in
            createIngredient(
                for: recipe,
                article: ingredient.article,
                quantity: ingredient.quantity,
                isOptional: ingredient.isOptional,
                in: modelContext
            )
        }
        
        // Assigner les ingrédients à la recette
        recipe.ingredients = recipeIngredients
        
        print("Recette '\(name)' créée avec succès")
        
        return recipe
    }
    
    /// Vérifie si une image existe dans les assets
    /// - Parameter imageName: Nom de l'image à vérifier
    /// - Returns: True si l'image existe, false sinon
    static func imageExists(named imageName: String) -> Bool {
        return UIImage(named: imageName) != nil
    }
}
