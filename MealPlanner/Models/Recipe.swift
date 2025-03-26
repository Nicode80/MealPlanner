import Foundation
import SwiftData

@Model
final class Recipe {
    var name: String
    var details: String?
    var photo: Data?  // Stockage direct de l'image en binaire
    
    // Relations - supprime les RecipeIngredient quand une recette est supprimée
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]?
    
    init(name: String, details: String? = nil, photo: Data? = nil) {
        self.name = name
        self.details = details
        self.photo = photo
    }
}

// Extension pour ajouter des fonctionnalités utiles
extension Recipe {
    var hasIngredients: Bool {
        return ingredients?.isEmpty == false
    }
}
