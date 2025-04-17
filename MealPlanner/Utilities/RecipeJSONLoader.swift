import Foundation
import SwiftData
import SwiftUI

/// Classe responsable du chargement et de l'interprétation des recettes depuis un fichier JSON
class RecipeJSONLoader {
    
    /// Structure pour décoder les recettes depuis JSON
    struct RecipeJSON: Codable {
        let name: String
        let details: String
        let imageName: String
        let ingredients: [IngredientJSON]
        
        struct IngredientJSON: Codable {
            let name: String
            let category: String
            let unit: String
            let quantity: Double
            let isOptional: Bool
        }
    }
    
    /// Charge les recettes depuis un JSON
    /// - Returns: Tableau de recettes décodées
    static func loadRecipesFromJSON() -> [RecipeJSON] {
        // Option 1: Charger depuis un bundle (fichier inclus dans l'app)
        guard let url = Bundle.main.url(forResource: "default_recipes", withExtension: "json") else {
            print("Fichier JSON des recettes introuvable dans le bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([RecipeJSON].self, from: data)
        } catch {
            print("Erreur lors du décodage du JSON des recettes: \(error)")
            return []
        }
    }
    
    /// Cette fonction remplace les fonctions de création de recettes individuelles
    /// - Parameters:
    ///   - modelContext: Contexte SwiftData pour insérer les recettes
    ///   - existingArticles: Dictionnaire d'articles existants à utiliser
    static func createRecipesFromJSON(in modelContext: ModelContext, using existingArticles: [String: Article]) {
        let recipes = loadRecipesFromJSON()
        
        if recipes.isEmpty {
            print("Aucune recette trouvée dans le JSON")
            return
        }
        
        print("Création de \(recipes.count) recettes depuis le JSON...")
        
        // 1. Extraire tous les ingrédients uniques du JSON
        let uniqueIngredients = extractUniqueIngredients(from: recipes)
        
        // 2. Créer ou récupérer tous les articles nécessaires
        let allArticles = createOrRetrieveArticles(uniqueIngredients: uniqueIngredients, existingArticles: existingArticles, modelContext: modelContext)
        
        // 3. Créer les recettes avec leurs ingrédients
        createRecipesWithIngredients(recipes: recipes, articles: allArticles, modelContext: modelContext)
    }
    
    /// Extrait tous les ingrédients uniques des recettes JSON
    /// - Parameter recipes: Liste des recettes JSON
    /// - Returns: Dictionnaire des ingrédients uniques avec leurs infos
    private static func extractUniqueIngredients(from recipes: [RecipeJSON]) -> [String: (category: String, unit: String)] {
        var uniqueIngredients: [String: (category: String, unit: String)] = [:]
        
        // Unités préférées pour certains ingrédients (priorité d'unités)
        let preferredUnits: [String: String] = [
            "Pommes de terre": "g",
            "Pomme de terre": "g",
            "Miel": "g",
            "Salade verte": "g"
        ]
        
        // Priorité des unités (du plus générique au plus spécifique)
        let unitPriority: [String] = ["kg", "g", "l", "ml", "pièce(s)", "cuillère(s) à soupe", "cuillère(s) à café", "pincée(s)"]
        
        // Normalisation des noms d'ingrédients (singulier/pluriel)
        let normalizationMap: [String: String] = [
            "Pommes de terre": "Pomme de terre",
            "Œufs": "Œuf",
            "Carottes": "Carotte",
            "Champignons de Paris": "Champignon de Paris",
            "Olives": "Olive"
        ]
        
        for recipe in recipes {
            for ingredient in recipe.ingredients {
                // Normaliser le nom
                let normalizedName = normalizationMap[ingredient.name] ?? ingredient.name
                
                // Si cet ingrédient existe déjà, vérifier quelle unité garder
                if let existing = uniqueIngredients[normalizedName] {
                    // Si une unité préférée est définie, l'utiliser
                    if let preferredUnit = preferredUnits[normalizedName] {
                        if ingredient.unit == preferredUnit {
                            uniqueIngredients[normalizedName] = (ingredient.category, ingredient.unit)
                        }
                    }
                    // Sinon comparer la priorité des unités
                    else {
                        let existingPriority = unitPriority.firstIndex(of: existing.unit) ?? Int.max
                        let newPriority = unitPriority.firstIndex(of: ingredient.unit) ?? Int.max
                        
                        if newPriority < existingPriority {
                            uniqueIngredients[normalizedName] = (ingredient.category, ingredient.unit)
                        }
                    }
                } else {
                    // Premier ajout de cet ingrédient
                    uniqueIngredients[normalizedName] = (ingredient.category, ingredient.unit)
                }
            }
        }
        
        return uniqueIngredients
    }
    
    /// Crée ou récupère tous les articles nécessaires
    /// - Parameters:
    ///   - uniqueIngredients: Dictionnaire des ingrédients uniques
    ///   - existingArticles: Articles existants
    ///   - modelContext: Contexte SwiftData
    /// - Returns: Dictionnaire des articles par nom
    private static func createOrRetrieveArticles(
        uniqueIngredients: [String: (category: String, unit: String)],
        existingArticles: [String: Article],
        modelContext: ModelContext
    ) -> [String: Article] {
        
        var articles = existingArticles
        
        // Normalisation des noms pour la recherche (map des variants vers le nom standard)
        let normalizationMap: [String: String] = [
            "Pommes de terre": "Pomme de terre",
            "Œufs": "Œuf",
            "Carottes": "Carotte",
            "Champignons de Paris": "Champignon de Paris"
        ]
        
        for (name, info) in uniqueIngredients {
            // Vérifier si l'article existe déjà (vérifier aussi les variants)
            let standardName = normalizationMap[name] ?? name
            
            if let existingArticle = articles[standardName] {
                // L'article existe déjà, le réutiliser
                articles[name] = existingArticle
            } else {
                // Créer un nouvel article
                let newArticle = RecipeUtilities.createArticle(
                    name: standardName,
                    category: info.category,
                    unit: info.unit,
                    in: modelContext
                )
                
                // Ajouter l'article au dictionnaire sous son nom et son nom standard
                articles[standardName] = newArticle
                if name != standardName {
                    articles[name] = newArticle
                }
                
                print("Nouvel article créé : \(standardName) (\(info.category), \(info.unit))")
            }
        }
        
        return articles
    }
    
    /// Crée les recettes avec leurs ingrédients
    /// - Parameters:
    ///   - recipes: Recettes JSON
    ///   - articles: Dictionnaire des articles
    ///   - modelContext: Contexte SwiftData
    private static func createRecipesWithIngredients(
        recipes: [RecipeJSON],
        articles: [String: Article],
        modelContext: ModelContext
    ) {
        for recipeData in recipes {
            // Charger l'image
            let photoData = DefaultRecipesManager.loadImageFromAssets(named: recipeData.imageName)
            
            // Créer la recette
            let recipe = Recipe(
                name: recipeData.name,
                details: recipeData.details,
                photo: photoData
            )
            
            modelContext.insert(recipe)
            
            // Créer les ingrédients
            var recipeIngredients: [RecipeArticle] = []
            
            for ingredientData in recipeData.ingredients {
                // Chercher l'article correspondant
                if let article = articles[ingredientData.name] {
                    let ingredient = RecipeUtilities.createIngredient(
                        for: recipe,
                        article: article,
                        quantity: ingredientData.quantity,
                        isOptional: ingredientData.isOptional,
                        in: modelContext
                    )
                    recipeIngredients.append(ingredient)
                } else {
                    print("⚠️ Article non trouvé pour l'ingrédient: \(ingredientData.name)")
                }
            }
            
            recipe.ingredients = recipeIngredients
            
            print("Recette '\(recipeData.name)' créée avec succès (\(recipeIngredients.count) ingrédients)")
        }
    }
}
