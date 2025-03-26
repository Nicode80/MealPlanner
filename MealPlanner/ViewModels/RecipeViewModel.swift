import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
class RecipeViewModel {
    private var modelContext: ModelContext
    
    var recipes: [Recipe] = []
    
    // Pour la création d'une nouvelle recette
    var newRecipeName = ""
    var newRecipeDetails = ""
    var newRecipePhotoData: Data?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchRecipes()
    }
    
    func fetchRecipes() {
        let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
        do {
            recipes = try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des recettes: \(error)")
        }
    }
    
    func createRecipe() -> Recipe? {
        guard !newRecipeName.isEmpty else { return nil }
        
        let recipe = Recipe(
            name: newRecipeName,
            details: newRecipeDetails.isEmpty ? nil : newRecipeDetails,
            photo: newRecipePhotoData
        )
        
        modelContext.insert(recipe)
        try? modelContext.save()
        fetchRecipes()
        
        // Réinitialiser les champs
        resetNewRecipeFields()
        
        return recipe
    }
    
    func resetNewRecipeFields() {
        newRecipeName = ""
        newRecipeDetails = ""
        newRecipePhotoData = nil
    }
    
    func addIngredientToRecipe(recipe: Recipe, ingredient: Ingredient, quantity: Double, isOptional: Bool = false) {
        let recipeIngredient = RecipeIngredient(
            recipe: recipe,
            ingredient: ingredient,
            quantity: quantity,
            isOptional: isOptional
        )
        
        modelContext.insert(recipeIngredient)
        
        if recipe.ingredients == nil {
            recipe.ingredients = [recipeIngredient]
        } else {
            recipe.ingredients?.append(recipeIngredient)
        }
        
        try? modelContext.save()
    }
    
    func removeIngredientFromRecipe(recipe: Recipe, recipeIngredient: RecipeIngredient) {
        if let index = recipe.ingredients?.firstIndex(where: { $0.id == recipeIngredient.id }) {
            recipe.ingredients?.remove(at: index)
            modelContext.delete(recipeIngredient)
            try? modelContext.save()
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        modelContext.delete(recipe)
        try? modelContext.save()
        fetchRecipes()
    }
    
    func updateRecipe(_ recipe: Recipe, name: String, details: String, photo: Data?) {
        recipe.name = name
        recipe.details = details.isEmpty ? nil : details
        recipe.photo = photo
        
        try? modelContext.save()
        fetchRecipes()
    }
}
