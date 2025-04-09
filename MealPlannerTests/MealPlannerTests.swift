import Testing
import SwiftData
@testable import MealPlanner

struct MealPlannerTests {
    
    // Test pour le calcul des quantités dans la liste de courses
    @Test func testShoppingListQuantityCalculation() async throws {
        // Créer un conteneur SwiftData en mémoire pour les tests
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try await ModelContainer(
            for: Recipe.self, Article.self, RecipeArticle.self,
            ShoppingList.self, ShoppingListItem.self,
            configurations: config
        )
        let modelContext = await container.mainContext
        
        // Créer des articles
        let pasta = Article(name: "Pâtes", category: "Épicerie salée", unit: "g", isFood: true)
        let tomato = Article(name: "Tomates", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
        let cheese = Article(name: "Parmesan", category: "Produits laitiers", unit: "g", isFood: true)
        
        modelContext.insert(pasta)
        modelContext.insert(tomato)
        modelContext.insert(cheese)
        
        // Créer une recette
        let recipe = Recipe(name: "Pasta a la norma")
        modelContext.insert(recipe)
        
        // Ajouter des ingrédients à la recette (quantités pour 1 personne)
        let ingredient1 = RecipeArticle(recipe: recipe, article: pasta, quantity: 100, isOptional: false)
        let ingredient2 = RecipeArticle(recipe: recipe, article: tomato, quantity: 2, isOptional: false)
        let ingredient3 = RecipeArticle(recipe: recipe, article: cheese, quantity: 20, isOptional: true)
        
        modelContext.insert(ingredient1)
        modelContext.insert(ingredient2)
        modelContext.insert(ingredient3)
        
        // Créer une liste de courses
        let shoppingList = ShoppingList()
        modelContext.insert(shoppingList)
        
        // Créer des repas planifiés
        let meal1 = PlannedMeal(
            recipe: recipe,
            numberOfPeople: 2,
            dayOfWeek: 0, // Lundi
            mealType: .dinner
        )
        
        let meal2 = PlannedMeal(
            recipe: recipe,
            numberOfPeople: 3,
            dayOfWeek: 3, // Jeudi
            mealType: .dinner
        )
        
        // Mettre à jour la liste de courses avec ces repas
        ShoppingListUpdater.update(
            with: [meal1, meal2],
            modelContext: modelContext,
            shoppingLists: [shoppingList],
            recipes: [recipe]
        )
        
        // Vérifier que les quantités sont correctement calculées (2 + 3 = 5 personnes)
        let items = shoppingList.items ?? []
        
        // Trouver les articles dans la liste
        let pastaItem = items.first { $0.article?.id == pasta.id }
        let tomatoItem = items.first { $0.article?.id == tomato.id }
        let cheeseItem = items.first { $0.article?.id == cheese.id }
        
        // Vérifier les quantités
        #expect(pastaItem?.quantity == 500) // 100g × 5 personnes
        #expect(tomatoItem?.quantity == 10) // 2 pièces × 5 personnes
        #expect(cheeseItem?.quantity == 100) // 20g × 5 personnes
        
        // Modifier manuellement une quantité
        if let pastaItem = pastaItem {
            pastaItem.quantity = 600
            pastaItem.manualQuantity = 100 // 100g ajoutés manuellement
        }
        
        // Ajouter un autre repas
        let meal3 = PlannedMeal(
            recipe: recipe,
            numberOfPeople: 1,
            dayOfWeek: 5, // Samedi
            mealType: .dinner
        )
        
        // Mettre à jour la liste de courses
        ShoppingListUpdater.update(
            with: [meal1, meal2, meal3],
            modelContext: modelContext,
            shoppingLists: [shoppingList],
            recipes: [recipe]
        )
        
        // Vérifier que l'ajustement manuel est préservé
        let updatedPastaItem = shoppingList.items?.first { $0.article?.id == pasta.id }
        #expect(updatedPastaItem?.quantity == 700) // 100g × 6 personnes + 100g manuels
    }
    
    // Test pour vérifier la fonctionnalité de suppression d'ingrédients des recettes
    @Test func testRemoveIngredientFromRecipe() async throws {
        // Créer un conteneur SwiftData en mémoire pour les tests
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try await ModelContainer(
            for: Recipe.self, Article.self, RecipeArticle.self,
            configurations: config
        )
        let modelContext = await container.mainContext
        
        // Créer un ViewModel
        let viewModel = RecipeViewModel(modelContext: modelContext)
        
        // Créer une recette
        let recipe = Recipe(name: "Test Recipe")
        modelContext.insert(recipe)
        
        // Créer des articles
        let article1 = Article(name: "Article 1", category: "Catégorie", unit: "pièce(s)")
        let article2 = Article(name: "Article 2", category: "Catégorie", unit: "pièce(s)")
        
        modelContext.insert(article1)
        modelContext.insert(article2)
        
        // Ajouter des ingrédients à la recette
        viewModel.addIngredientToRecipe(recipe: recipe, article: article1, quantity: 1)
        viewModel.addIngredientToRecipe(recipe: recipe, article: article2, quantity: 2)
        
        // Vérifier que la recette a 2 ingrédients
        #expect(recipe.ingredients?.count == 2)
        
        // Supprimer un ingrédient
        if let ingredient = recipe.ingredients?.first(where: { $0.article?.id == article1.id }) {
            viewModel.removeIngredientFromRecipe(recipe: recipe, recipeArticle: ingredient)
        }
        
        // Vérifier qu'il ne reste qu'un ingrédient
        #expect(recipe.ingredients?.count == 1)
        #expect(recipe.ingredients?.first?.article?.id == article2.id)
    }
    
    // Test pour vérifier la détection des articles similaires
    @Test func testSimilarArticleDetection() async throws {
        // Créer un conteneur SwiftData en mémoire pour les tests
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try await ModelContainer(for: Article.self, configurations: config)
        let modelContext = await container.mainContext
        
        // Créer le ViewModel
        let viewModel = ArticlesViewModel(modelContext: modelContext)
        
        // Créer un article
        let tomato = Article(name: "Tomates", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
        modelContext.insert(tomato)
        
        // Forcer le rafraîchissement de la liste des articles
        viewModel.fetchArticles()
        
        // Tester la détection avec le même nom
        let exactMatch = viewModel.checkForSimilarArticle(name: "Tomates", forRecipe: true)
        #expect(exactMatch != nil)
        #expect(exactMatch?.id == tomato.id)
        
        // Tester avec une légère différence (un caractère)
        let closeMatch = viewModel.checkForSimilarArticle(name: "Tomatez", forRecipe: true)
        #expect(closeMatch != nil)
        #expect(closeMatch?.id == tomato.id)
        
        // Tester avec un nom différent
        let noMatch = viewModel.checkForSimilarArticle(name: "Pommes", forRecipe: true)
        #expect(noMatch == nil)
    }
    
    // Test des ajustements manuels dans la liste de courses
    @Test func testManualAdjustmentsInShoppingList() async throws {
        // Créer un conteneur SwiftData en mémoire pour les tests
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try await ModelContainer(
            for: Recipe.self, Article.self, RecipeArticle.self,
            ShoppingList.self, ShoppingListItem.self,
            configurations: config
        )
        let modelContext = await container.mainContext
        
        // Créer une liste de courses
        let shoppingList = ShoppingList()
        modelContext.insert(shoppingList)
        
        // Créer quelques articles
        let tomato = Article(name: "Tomates", category: "Fruits et légumes", unit: "pièce(s)", isFood: true)
        modelContext.insert(tomato)
        
        // Ajouter un article à la liste de courses manuellement
        let item = ShoppingListItem(
            shoppingList: shoppingList,
            article: tomato,
            quantity: 5,
            isManuallyAdded: true,
            manualQuantity: 5
        )
        modelContext.insert(item)
        
        if shoppingList.items == nil {
            shoppingList.items = [item]
        } else {
            shoppingList.items?.append(item)
        }
        
        // Créer une recette qui utilise le même article
        let recipe = Recipe(name: "Sauce tomate")
        modelContext.insert(recipe)
        
        let recipeIngredient = RecipeArticle(recipe: recipe, article: tomato, quantity: 3, isOptional: false)
        modelContext.insert(recipeIngredient)
        
        // Ajouter la recette au planning
        let meal = PlannedMeal(
            recipe: recipe,
            numberOfPeople: 2,
            dayOfWeek: 0,
            mealType: .dinner
        )
        
        // Mettre à jour la liste de courses
        ShoppingListUpdater.update(
            with: [meal],
            modelContext: modelContext,
            shoppingLists: [shoppingList],
            recipes: [recipe]
        )
        
        // Vérifier que la quantité inclut la partie manuelle (5) plus les tomates de la recette (3 × 2 = 6)
        let updatedItem = shoppingList.items?.first { $0.article?.id == tomato.id }
        #expect(updatedItem?.quantity == 11) // 5 (manuel) + 6 (recette)
        #expect(updatedItem?.manualQuantity == 5) // La quantité manuelle reste la même
        
        // Simuler l'ajustement manuel de la quantité
        if let updatedItem = updatedItem {
            updatedItem.quantity = 15
            updatedItem.manualQuantity = 9 // 9 au lieu de 5
        }
        
        // Supprimer la recette du planning
        ShoppingListUpdater.update(
            with: [],
            modelContext: modelContext,
            shoppingLists: [shoppingList],
            recipes: [recipe]
        )
        
        // Vérifier que seule la quantité manuelle reste
        let finalItem = shoppingList.items?.first { $0.article?.id == tomato.id }
        #expect(finalItem?.quantity == 9) // Seulement la quantité manuelle reste
        #expect(finalItem?.manualQuantity == 9)
    }
}
