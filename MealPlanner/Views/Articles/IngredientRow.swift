import SwiftUI
import SwiftData

struct IngredientRow: View {
    let ingredient: Ingredient
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(ingredient.name)
                    .font(.body)
                Text(ingredient.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(ingredient.unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    // Création d'un ingrédient de test pour la prévisualisation
    let ingredient = Ingredient(name: "Carotte", category: "Fruits et légumes", unit: "pièce(s)")
    
    return IngredientRow(ingredient: ingredient)
        .padding()
        .previewDisplayName("Ingredient Row Preview")
        .previewLayout(.sizeThatFits)
}
