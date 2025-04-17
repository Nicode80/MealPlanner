import SwiftUI
import SwiftData

struct ShoppingListItemRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: ShoppingListItem
    @State private var isEditing: Bool = false
    @State private var editedQuantity: Double
    
    init(item: ShoppingListItem) {
        self.item = item
        // Initialiser la quantité éditée avec la valeur actuelle
        self._editedQuantity = State(initialValue: item.quantity)
    }
    
    var body: some View {
        HStack {
            Button {
                item.isChecked.toggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.square" : "square")
                    .foregroundColor(item.isChecked ? .green : .primary)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Text(item.article?.name ?? "Article inconnu")
                .strikethrough(item.isChecked)
                .foregroundColor(item.isChecked ? .secondary : .primary)
            
            Spacer()
            
            if isEditing {
                // Mode édition: afficher un stepper pour la quantité
                HStack(spacing: 5) {
                    Button {
                        let step = getStepValue(for: item.article?.unit ?? "")
                        editedQuantity = max(step, editedQuantity - step)
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    if isDecimalUnit(item.article?.unit ?? "") {
                        TextField("", value: $editedQuantity, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                    } else {
                        TextField("", value: $editedQuantity, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                    }
                    
                    Button {
                        let step = getStepValue(for: item.article?.unit ?? "")
                        editedQuantity += step
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button {
                        saveChanges()
                    } label: {
                        Text("OK")
                            .foregroundColor(.blue)
                            .bold()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            } else {
                // Mode normal: afficher la quantité convertie pour les courses
                HStack {
                    // Utiliser formattedShoppingQuantity au lieu de l'affichage direct
                    Text(item.formattedShoppingQuantity)
                        .foregroundColor(.secondary)
                    
                    Button {
                        // Entrer en mode édition
                        isEditing = true
                        editedQuantity = item.quantity
                    } label: {
                        Image(systemName: "pencil")
                            .font(.body)  // Augmenter la taille (au lieu de .caption)
                            .foregroundColor(.blue)  // Changer la couleur (au lieu de .gray)
                            .padding(8)  // Ajouter du padding pour une zone de toucher plus grande
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .onDisappear {
            // Si nous sommes en mode édition lorsque la vue disparaît, sauvegarder les modifications
            if isEditing {
                saveChanges()
            }
        }
    }
    
    // Détermine si une unité utilise des valeurs décimales
    private func isDecimalUnit(_ unit: String) -> Bool {
        return ["kg", "l", "L"].contains(unit)
    }
    
    // Obtient le pas d'incrémentation pour une unité donnée
    private func getStepValue(for unit: String) -> Double {
        return isDecimalUnit(unit) ? 0.1 : 1.0
    }
    
    // Fonction pour sauvegarder les changements
    private func saveChanges() {
        // Calculer la différence entre la quantité éditée et la quantité actuelle
        let difference = editedQuantity - (item.quantity - item.manualQuantity)
        
        // Mettre à jour la quantité manuelle
        item.manualQuantity = difference
        
        // Mettre à jour la quantité totale
        item.quantity = editedQuantity
        
        // Marquer comme modifié manuellement
        item.isManuallyAdded = true
        
        // Quitter le mode édition
        isEditing = false
    }
}
