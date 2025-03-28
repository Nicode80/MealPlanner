import Foundation
// Commenter ou supprimer l'import SwiftData
// import SwiftData

// Commenter la directive @Model
// @Model
final class Ingredient {
    var name: String
    var category: String
    var unit: String
    
    // Relations déjà commentées
    
    init(name: String, category: String, unit: String) {
        self.name = name
        self.category = category
        self.unit = unit
    }
}
