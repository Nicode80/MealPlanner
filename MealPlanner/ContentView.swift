import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            NavigationStack {
                RecipeListView()
            }
            .tabItem {
                Label("Recettes", systemImage: "book")
            }
            
            NavigationStack {
                ShoppingListView()
            }
            .tabItem {
                Label("Courses", systemImage: "cart")
            }
            
            NavigationStack {
                WeeklyPlannerView()
            }
            .tabItem {
                Label("Planning", systemImage: "calendar")
            }
        }
    }
}

#Preview {
    // Création d'un conteneur en mémoire pour la prévisualisation
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Recipe.self, Ingredient.self, RecipeIngredient.self,
        ShoppingList.self, ShoppingListItem.self,
        configurations: config
    )
    
    // Ajout de données d'exemple
    let context = container.mainContext
    SampleData.createSampleData(in: context)
    
    return ContentView()
        .modelContainer(container)
}

// Utilitaire pour générer des données d'exemple
struct SampleData {
    static func createSampleData(in context: ModelContext) {
        // Ingrédients d'exemple
        let carotte = Ingredient(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)")
        let tomate = Ingredient(name: "Tomate", category: "Fruits et légumes", unit: "pièce(s)")
        let oignon = Ingredient(name: "Oignon", category: "Fruits et légumes", unit: "pièce(s)")
        let riz = Ingredient(name: "Riz", category: "Épicerie salée", unit: "g")
        let poulet = Ingredient(name: "Blanc de poulet", category: "Viandes", unit: "g")
        
        context.insert(carotte)
        context.insert(tomate)
        context.insert(oignon)
        context.insert(riz)
        context.insert(poulet)
        
        // Recettes d'exemple
        let rizPoulet = Recipe(name: "Riz au poulet", details: "Un plat simple et rapide")
        context.insert(rizPoulet)
        
        let recipeIngredient1 = RecipeIngredient(recipe: rizPoulet, ingredient: riz, quantity: 75, isOptional: false)
        let recipeIngredient2 = RecipeIngredient(recipe: rizPoulet, ingredient: poulet, quantity: 150, isOptional: false)
        let recipeIngredient3 = RecipeIngredient(recipe: rizPoulet, ingredient: oignon, quantity: 0.5, isOptional: true)
        
        context.insert(recipeIngredient1)
        context.insert(recipeIngredient2)
        context.insert(recipeIngredient3)
        
        // Liste de courses d'exemple
        let shoppingList = ShoppingList()
        context.insert(shoppingList)
        
        let shoppingItem1 = ShoppingListItem(shoppingList: shoppingList, ingredient: carotte, quantity: 3)
        let shoppingItem2 = ShoppingListItem(shoppingList: shoppingList, ingredient: tomate, quantity: 4)
        
        context.insert(shoppingItem1)
        context.insert(shoppingItem2)
    }
}
