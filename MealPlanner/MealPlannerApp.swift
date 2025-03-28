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
            Article.self,
            RecipeArticle.self,
            ShoppingList.self,
            ShoppingListItem.self
        ], inMemory: false)
    }
}
