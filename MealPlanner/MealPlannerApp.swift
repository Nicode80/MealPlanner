import SwiftUI
import SwiftData
import Observation

@main
struct MealPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Recipe.self,
            Article.self,  // Nouveau modèle Article (remplace Ingredient)
            RecipeIngredient.self,
            ShoppingList.self,
            ShoppingListItem.self
        ], inMemory: false)
    }
}
