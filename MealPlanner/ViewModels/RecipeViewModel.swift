import Foundation
import SwiftData

class RecipeViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    @Published var recipes: [Recipe] = []
    
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
    
    func addRecipe(name: String, details: String? = nil, photo: Data? = nil) -> Recipe {
        let recipe = Recipe(name: name, details: details, photo: photo)
        modelContext.insert(recipe)
        saveContext()
        fetchRecipes()
        return recipe
    }
    
    func addIngredientToRecipe(recipe: Recipe, ingredient: Ingredient, quantity: Double, isOptional: Bool = false) {
        let recipeIngredient = RecipeIngredient(recipe: recipe, ingredient: ingredient, quantity: quantity, isOptional: isOptional)
        
        if recipe.ingredients == nil {
            recipe.ingredients = [recipeIngredient]
        } else {
            recipe.ingredients?.append(recipeIngredient)
        }
        
        saveContext()
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        modelContext.delete(recipe)
        saveContext()
        fetchRecipes()
    }
    
    func updateRecipe(_ recipe: Recipe) {
        saveContext()
        fetchRecipes()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde du contexte: \(error)")
        }
    }
}
