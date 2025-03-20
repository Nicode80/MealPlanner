import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    // Quantité pour 1 personne
    var quantity: Double
    var isOptional: Bool
    
    // Relations - ne supprime pas les entités liées
    @Relationship(deleteRule: .nullify)
    var recipe: Recipe?
    
    @Relationship(deleteRule: .nullify)
    var ingredient: Ingredient?
    
    init(recipe: Recipe? = nil, ingredient: Ingredient? = nil, quantity: Double, isOptional: Bool = false) {
        self.recipe = recipe
        self.ingredient = ingredient
        self.quantity = quantity
        self.isOptional = isOptional
    }
}
