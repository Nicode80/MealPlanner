import SwiftUI
import SwiftData
import Observation  // Ajout de l'import pour @Bindable

@main
struct MealPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Recipe.self,
            Ingredient.self,
            RecipeIngredient.self,
            ShoppingList.self,
            ShoppingListItem.self
        ])
    }
}
