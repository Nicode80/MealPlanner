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
    var article: Article?
    
    init(recipe: Recipe? = nil, article: Article? = nil, quantity: Double, isOptional: Bool = false) {
        self.recipe = recipe
        self.article = article
        self.quantity = quantity
        self.isOptional = isOptional
    }
}
