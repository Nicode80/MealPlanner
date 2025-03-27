import SwiftUI
import SwiftData

struct IngredientSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: IngredientsViewModel?
    @State private var quantity: Double = 1.0
    @State private var isOptional: Bool = false
    @State private var showingAddNewIngredient = false
    @State private var selectedCategoryFilter: String?
    @State private var forRecipeContext: Bool = true // Par défaut, on est dans le contexte d'une recette
    
    var onIngredientSelected: (Ingredient, Double, Bool) -> Void
    
    init(forRecipe: Bool = true, onIngredientSelected: @escaping (Ingredient, Double, Bool) -> Void) {
        self.onIngredientSelected = onIngredientSelected
        self._forRecipeContext = State(initialValue: forRecipe)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let vm = viewModel {
                    // Barre de recherche
                    TextField("Rechercher un ingrédient", text: Binding(
                        get: { vm.searchText },
                        set: { vm.searchIngredient(query: $0, forRecipe: forRecipeContext) }
                    ))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Filtres par catégorie
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button {
                                selectedCategoryFilter = nil
                            } label: {
                                Text("Tous")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategoryFilter == nil ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategoryFilter == nil ? .white : .primary)
                                    .cornerRadius(20)
                            }
                            
                            ForEach(vm.getCategories(forRecipe: forRecipeContext), id: \.self) { category in
                                Button {
                                    selectedCategoryFilter = category
                                } label: {
                                    Text(category)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategoryFilter == category ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedCategoryFilter == category ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Résultats de recherche et sélection
                    List {
                        // Option pour créer un nouvel ingrédient
                        Section {
                            Button {
                                vm.searchText = ""
                                showingAddNewIngredient = true
                            } label: {
                                Label("Créer un nouvel ingrédient", systemImage: "plus.circle")
                            }
                        }
                        
                        // Afficher les ingrédients par catégorie
                        let filteredCategories = vm.ingredientsByCategory.filter {
                            selectedCategoryFilter == nil || $0.key == selectedCategoryFilter
                        }
                        
                        ForEach(filteredCategories.keys.sorted(), id: \.self) { category in
                            Section(header: Text(category)) {
                                ForEach(filteredCategories[category] ?? []) { ingredient in
                                    Button {
                                        vm.selectedIngredient = ingredient
                                    } label: {
                                        HStack {
                                            Text(ingredient.name)
                                            
                                            Spacer()
                                            
                                            Text(ingredient.unit)
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                            
                                            if vm.selectedIngredient?.id == ingredient.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        // Suggestions d'ingrédients similaires
                        if !vm.similarIngredientSuggestions.isEmpty {
                            Section(header: Text("Suggestions similaires")) {
                                ForEach(vm.similarIngredientSuggestions) { ingredient in
                                    Button {
                                        vm.selectedIngredient = ingredient
                                    } label: {
                                        HStack {
                                            Text(ingredient.name)
                                            
                                            Spacer()
                                            
                                            Text(ingredient.unit)
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                            
                                            if vm.selectedIngredient?.id == ingredient.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    // Options pour l'ingrédient sélectionné
                    if let selectedIngredient = vm.selectedIngredient {
                        VStack(spacing: 16) {
                            Divider()
                            
                            Text("Quantité pour 1 personne")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            // Sélecteur de quantité avec boutons + et -
                            HStack {
                                Button(action: {
                                    let step = vm.getStepValue(for: selectedIngredient.unit)
                                    quantity = max(step, quantity - step)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                if vm.isDecimalUnit(selectedIngredient.unit) {
                                    // Pour kg/l, afficher avec une décimale
                                    TextField("Quantité", value: $quantity, format: .number.precision(.fractionLength(1)))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80)
                                } else {
                                    // Pour les autres unités, afficher en nombres entiers
                                    TextField("Quantité", value: $quantity, format: .number)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    let step = vm.getStepValue(for: selectedIngredient.unit)
                                    quantity += step
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Unité de mesure
                            Text(selectedIngredient.unit)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Toggle("Ingrédient optionnel", isOn: $isOptional)
                                .padding(.horizontal)
                            
                            Button {
                                onIngredientSelected(selectedIngredient, quantity, isOptional)
                                dismiss()
                            } label: {
                                Text("Ajouter à la recette")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .padding(.bottom)
                        }
                        .padding(.top)
                        .background(Color(.systemBackground))
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Ajouter un ingrédient")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddNewIngredient) {
                if let vm = viewModel {
                    AddNewIngredientView(
                        viewModel: vm,
                        forRecipe: forRecipeContext,
                        onIngredientCreated: { ingredient in
                            vm.selectedIngredient = ingredient
                            vm.fetchIngredients()
                        }
                    )
                }
            }
            .onAppear {
                print("IngredientSelectionView appeared")
                if viewModel == nil {
                    viewModel = IngredientsViewModel(modelContext: modelContext)
                    // Initialiser la recherche avec les bons filtres
                    viewModel?.searchIngredient(query: "", forRecipe: forRecipeContext)
                }
            }
        }
    }
}
