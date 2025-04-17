import SwiftUI
import SwiftData
import Observation

@main
struct MealPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Vérifier si nous avons besoin d'initialiser les données par défaut
                    initializeDefaultDataIfNeeded()
                }
        }
        .modelContainer(for: [
            Recipe.self,
            Article.self,
            RecipeArticle.self,
            ShoppingList.self,
            ShoppingListItem.self
        ], inMemory: ProcessInfo.processInfo.arguments.contains("-UITesting"))
    }
    
    // Fonction pour initialiser les données par défaut si nécessaire
    private func initializeDefaultDataIfNeeded() {
        let dataManager = DefaultRecipesManager.shared
        
        // Vérifier si c'est le premier lancement
        if dataManager.isFirstLaunch() {
            print("Premier lancement détecté, initialisation des données par défaut...")
            
            // Obtenez le ModelContainer
            do {
                let modelContainer = try ModelContainer(
                    for: Recipe.self, Article.self, RecipeArticle.self,
                    ShoppingList.self, ShoppingListItem.self
                )
                
                // Obtenez le ModelContext
                let modelContext = modelContainer.mainContext
                
                // Créer les recettes par défaut
                dataManager.createDefaultRecipes(in: modelContext)
                
            } catch {
                print("Erreur: Impossible de créer le ModelContainer: \(error)")
            }
        }
    }
}
