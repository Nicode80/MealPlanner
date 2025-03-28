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
        for: Recipe.self, Article.self, RecipeArticle.self,
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
        // Articles alimentaires d'exemple
        let carotte = Article(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
        let tomate = Article(name: "Tomate", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
        let oignon = Article(name: "Oignon", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
        let riz = Article(name: "Riz", category: "Épicerie salée", unit: "g", isFood: true)
        let poulet = Article(name: "Blanc de poulet", category: "Viandes", unit: "g", isFood: true)
        
        // Article non-alimentaire d'exemple
        let savon = Article(name: "Savon", category: "Hygiène et beauté", unit: "pièce(s)", isFood: false)
        
        context.insert(carotte)
        context.insert(tomate)
        context.insert(oignon)
        context.insert(riz)
        context.insert(poulet)
        context.insert(savon)
        
        // Recettes d'exemple
        let rizPoulet = Recipe(name: "Riz au poulet", details: "Un plat simple et rapide")
        context.insert(rizPoulet)
        
        let recipeIngredient1 = RecipeArticle(recipe: rizPoulet, article: riz, quantity: 75, isOptional: false)
        let recipeIngredient2 = RecipeArticle(recipe: rizPoulet, article: poulet, quantity: 150, isOptional: false)
        let recipeIngredient3 = RecipeArticle(recipe: rizPoulet, article: oignon, quantity: 0.5, isOptional: true)
        
        context.insert(recipeIngredient1)
        context.insert(recipeIngredient2)
        context.insert(recipeIngredient3)
        
        // Liste de courses d'exemple
        let shoppingList = ShoppingList()
        context.insert(shoppingList)
        
        let shoppingItem1 = ShoppingListItem(shoppingList: shoppingList, article: carotte, quantity: 3)
        let shoppingItem2 = ShoppingListItem(shoppingList: shoppingList, article: tomate, quantity: 4)
        let shoppingItem3 = ShoppingListItem(shoppingList: shoppingList, article: savon, quantity: 1)
        
        context.insert(shoppingItem1)
        context.insert(shoppingItem2)
        context.insert(shoppingItem3)
    }
}
