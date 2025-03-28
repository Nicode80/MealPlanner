import Foundation
import SwiftData

@Model
final class Article {
    var name: String
    var category: String  // Pour regrouper par rayon dans le supermarché
    var unit: String      // Unité de mesure (g, kg, pièce, etc.)
    var isFood: Bool      // True si c'est un aliment, false sinon
    
    // Relations - empêcher la suppression d'un article s'il est référencé
    @Relationship(deleteRule: .deny, inverse: \RecipeIngredient.article)
    var recipeIngredients: [RecipeIngredient]?
    
    @Relationship(deleteRule: .deny, inverse: \ShoppingListItem.article)
    var shoppingListItems: [ShoppingListItem]?
    
    init(name: String, category: String, unit: String, isFood: Bool = true) {
        self.name = name
        self.category = category
        self.unit = unit
        self.isFood = isFood
    }
}
