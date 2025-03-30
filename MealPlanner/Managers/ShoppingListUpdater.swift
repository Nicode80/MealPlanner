import Foundation
import SwiftData

// Service pour la mise à jour de la liste de courses
struct ShoppingListUpdater {
    static func update(with plannedMeals: [PlannedMeal], modelContext: ModelContext, shoppingLists: [ShoppingList], recipes: [Recipe]) {
        // Créer ou récupérer la liste de courses
        let shoppingList = getOrCreateShoppingList(from: shoppingLists, modelContext: modelContext)
        
        // Résoudre les recettes
        let mealsWithRecipes = resolveMealsWithRecipes(plannedMeals: plannedMeals, recipes: recipes)
        
        // Mettre à jour les articles
        updateShoppingItems(
            shoppingList: shoppingList,
            plannedMeals: mealsWithRecipes,
            modelContext: modelContext
        )
    }
    
    // Résoudre les recettes à partir des identifiants
    private static func resolveMealsWithRecipes(plannedMeals: [PlannedMeal], recipes: [Recipe]) -> [ResolvedMeal] {
        return plannedMeals.compactMap { meal in
            if let recipe = recipes.first(where: { $0.persistentModelID == meal.recipeId }) {
                return ResolvedMeal(recipe: recipe, numberOfPeople: meal.numberOfPeople)
            }
            return nil
        }
    }
    
    private static func getOrCreateShoppingList(from shoppingLists: [ShoppingList], modelContext: ModelContext) -> ShoppingList {
        if let existingList = shoppingLists.first {
            return existingList
        } else {
            let newList = ShoppingList()
            modelContext.insert(newList)
            return newList
        }
    }
    
    private static func updateShoppingItems(shoppingList: ShoppingList, plannedMeals: [ResolvedMeal], modelContext: ModelContext) {
        // 1. Créer un dictionnaire des articles existants
        var existingItemsByArticle = [Article: ShoppingListItem]()
        if let items = shoppingList.items {
            for item in items {
                if let article = item.article {
                    existingItemsByArticle[article] = item
                }
            }
        }
        
        // 2. Calculer les quantités des recettes
        var recipeQuantities = [Article: Double]()
        for meal in plannedMeals {
            if let ingredients = meal.recipe.ingredients {
                for ingredient in ingredients {
                    if let article = ingredient.article {
                        let quantity = ingredient.quantity * Double(meal.numberOfPeople)
                        recipeQuantities[article, default: 0] += quantity
                    }
                }
            }
        }
        
        // 3. Traiter tous les articles existants
        var processedArticles = Set<Article>()
        
        // 3a. D'abord, mettre à jour les articles qui sont dans les recettes
        for (article, recipeQuantity) in recipeQuantities {
            if let existingItem = existingItemsByArticle[article] {
                // Calculer la nouvelle quantité totale: recette + ajustement manuel
                let newTotalQuantity = recipeQuantity + existingItem.manualQuantity
                
                // Mettre à jour la quantité totale
                existingItem.quantity = max(0, newTotalQuantity) // Éviter les quantités négatives
                
                // Marquer comme traité
                processedArticles.insert(article)
            } else {
                // L'article n'existe pas encore, donc créer un nouvel élément
                let newItem = ShoppingListItem(
                    shoppingList: shoppingList,
                    article: article,
                    quantity: recipeQuantity,
                    isManuallyAdded: false,
                    manualQuantity: 0.0
                )
                modelContext.insert(newItem)
                if shoppingList.items == nil {
                    shoppingList.items = [newItem]
                } else {
                    shoppingList.items?.append(newItem)
                }
                
                // Marquer comme traité
                processedArticles.insert(article)
            }
        }
        
        // 3b. Ensuite, conserver les articles ajoutés manuellement qui ne sont plus dans les recettes
        if let items = shoppingList.items {
            for item in items {
                if let article = item.article, !processedArticles.contains(article) {
                    if item.isManuallyAdded && item.manualQuantity > 0 {
                        // Garder les articles manuels avec une quantité positive
                        // La quantité totale devient simplement la quantité manuelle
                        item.quantity = item.manualQuantity
                    } else if !item.isManuallyAdded {
                        // Supprimer les articles non manuels qui ne sont plus nécessaires
                        modelContext.delete(item)
                        shoppingList.items?.removeAll(where: { $0.id == item.id })
                    }
                }
            }
        }
        
        // 4. Mettre à jour la date de modification
        shoppingList.modificationDate = Date()
    }
}

// Structure pour représenter un repas résolu avec une recette
struct ResolvedMeal {
    let recipe: Recipe
    let numberOfPeople: Int
}
