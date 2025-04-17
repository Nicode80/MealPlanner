import Foundation
import SwiftData

/// Classe responsable de la création des recettes par défaut
class DefaultRecipesProvider {
    
    /// Crée toutes les recettes par défaut
    /// - Parameters:
    ///   - modelContext: Contexte SwiftData pour insérer les recettes
    ///   - articles: Dictionnaire contenant tous les articles disponibles
    static func createAllRecipes(in modelContext: ModelContext, using articles: [String: Article]) {
        // 1. Convertir le dictionnaire original indexé par clé en dictionnaire indexé par nom d'article
        var articlesByName: [String: Article] = [:]
        
        for (_, article) in articles {
            articlesByName[article.name] = article
        }
        
        // 2. Charger les recettes depuis le JSON (si disponible)
        if Bundle.main.url(forResource: "default_recipes", withExtension: "json") != nil {
            // Utiliser le chargeur JSON si le fichier existe
            RecipeJSONLoader.createRecipesFromJSON(in: modelContext, using: articlesByName)
        } else {
            // Sinon, créer des recettes par défaut codées en dur
            print("Fichier JSON non trouvé, création des recettes codées en dur...")
            createDefaultHardcodedRecipes(in: modelContext, using: articles)
        }
        
        print("Toutes les recettes ont été créées")
    }
    
    // Méthode de secours pour créer quelques recettes codées en dur si le JSON n'est pas disponible
    private static func createDefaultHardcodedRecipes(in modelContext: ModelContext, using articles: [String: Article]) {
        // Créer seulement quelques recettes de base
        createPatesCarbonaraRecipe(in: modelContext, using: articles)
        createHachisParmentier(in: modelContext, using: articles)
        
        // On peut ajouter d'autres recettes ici au besoin
    }
    
    // MARK: - Recettes codées en dur (conservées comme solution de secours)
    
    // Pâtes à la carbonara - conservé comme exemple
    private static func createPatesCarbonaraRecipe(in modelContext: ModelContext, using articles: [String: Article]) {
        let photoData = DefaultRecipesManager.loadImageFromAssets(named: "pates-carbo")
        
        let recipe = Recipe(
            name: "Pâtes à la carbonara",
            details: "Un classique de la cuisine italienne, rapide à préparer et délicieux. Cette recette traditionnelle est préparée avec des pâtes, des lardons et du parmesan. Parfait pour un repas convivial.",
            photo: photoData
        )
        
        modelContext.insert(recipe)
        
        let ingredients = [
            createIngredient(for: recipe, article: articles["spaghetti"]!, quantity: 100, in: modelContext),
            createIngredient(for: recipe, article: articles["lardons"]!, quantity: 50, in: modelContext),
            createIngredient(for: recipe, article: articles["œuf"]!, quantity: 1, in: modelContext),
            createIngredient(for: recipe, article: articles["parmesan"]!, quantity: 20, isOptional: true, in: modelContext),
            createIngredient(for: recipe, article: articles["sel"]!, quantity: 1, in: modelContext),
            createIngredient(for: recipe, article: articles["poivre"]!, quantity: 1, in: modelContext),
            createIngredient(for: recipe, article: articles["ail"]!, quantity: 1, isOptional: true, in: modelContext)
        ]
        
        recipe.ingredients = ingredients
        
        print("Recette 'Pâtes à la carbonara' créée avec succès")
    }
    
    // Hachis Parmentier - conservé comme exemple
    private static func createHachisParmentier(in modelContext: ModelContext, using articles: [String: Article]) {
        let photoData = DefaultRecipesManager.loadImageFromAssets(named: "hachis-parmentier")
        
        let recipe = Recipe(
            name: "Hachis Parmentier",
            details: "Un grand classique de la cuisine familiale française, le hachis parmentier est composé d'une couche de viande hachée recouverte d'une purée de pommes de terre gratinée. Un plat complet et réconfortant.",
            photo: photoData
        )
        
        modelContext.insert(recipe)
        
        let ingredients = [
            createIngredient(for: recipe, article: articles["pomme de terre"]!, quantity: 4, in: modelContext),
            createIngredient(for: recipe, article: articles["boeuf haché"]!, quantity: 150, in: modelContext),
            createIngredient(for: recipe, article: articles["oignon"]!, quantity: 1, in: modelContext),
            createIngredient(for: recipe, article: articles["ail"]!, quantity: 1, in: modelContext),
            createIngredient(for: recipe, article: articles["carotte"]!, quantity: 1, isOptional: true, in: modelContext),
            createIngredient(for: recipe, article: articles["beurre"]!, quantity: 30, in: modelContext),
            createIngredient(for: recipe, article: articles["lait"]!, quantity: 100, in: modelContext),
            createIngredient(for: recipe, article: articles["gruyère"]!, quantity: 50, in: modelContext),
            createIngredient(for: recipe, article: articles["sel"]!, quantity: 1, in: modelContext),
            createIngredient(for: recipe, article: articles["poivre"]!, quantity: 1, in: modelContext),
            createIngredient(for: recipe, article: articles["muscade"]!, quantity: 1, isOptional: true, in: modelContext)
        ]
        
        recipe.ingredients = ingredients
        
        print("Recette 'Hachis Parmentier' créée avec succès")
    }
    
    // MARK: - Utilitaires
    
    /// Fonction utilitaire pour créer un ingrédient (RecipeArticle)
    private static func createIngredient(for recipe: Recipe, article: Article, quantity: Double, isOptional: Bool = false, in modelContext: ModelContext) -> RecipeArticle {
        let ingredient = RecipeArticle(recipe: recipe, article: article, quantity: quantity, isOptional: isOptional)
        modelContext.insert(ingredient)
        return ingredient
    }
}
