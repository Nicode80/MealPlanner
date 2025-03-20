import Foundation
import SwiftData

@Model
final class Ingredient {
    var name: String
    var category: String  // Pour regrouper par rayon dans le supermarché
    var unit: String      // Unité de mesure (g, kg, pièce, etc.)
    
    // Relations - empêcher la suppression d'un ingrédient s'il est référencé
    @Relationship(deleteRule: .deny, inverse: \RecipeIngredient.ingredient)
    var recipeIngredients: [RecipeIngredient]?
    
    @Relationship(deleteRule: .deny, inverse: \ShoppingListItem.ingredient)
    var shoppingListItems: [ShoppingListItem]?
    
    init(name: String, category: String, unit: String) {
        self.name = name
        self.category = category
        self.unit = unit
    }
}
