import SwiftUI
import SwiftData

struct ArticleSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: ArticlesViewModel?
    @State private var quantity: Double = 1.0
    @State private var isOptional: Bool = false
    @State private var showingAddNewArticle = false
    @State private var selectedCategoryFilter: String?
    @State private var forRecipeContext: Bool = true // Par défaut, on est dans le contexte d'une recette
    
    var onArticleSelected: (Article, Double, Bool) -> Void
    var recipeName: String? // Paramètre optionnel pour le nom de la recette
    
    init(forRecipe: Bool = true, recipeName: String? = nil, onArticleSelected: @escaping (Article, Double, Bool) -> Void) {
        self.onArticleSelected = onArticleSelected
        self._forRecipeContext = State(initialValue: forRecipe)
        self.recipeName = recipeName
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let vm = viewModel {
                    // Barre de recherche
                    TextField("Rechercher un article", text: Binding(
                        get: { vm.searchText },
                        set: { vm.searchArticle(query: $0, forRecipe: forRecipeContext) }
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
                    
                    // Liste des résultats
                    // Reste du corps de la vue...
                    
                    // CODE EXISTANT POUR LA LISTE ET LE RESTE DE LA VUE
                    List {
                        // Option pour créer un nouvel article
                        Section {
                            Button {
                                vm.searchText = ""
                                showingAddNewArticle = true
                            } label: {
                                Label(forRecipeContext ? "Créer un nouvel ingrédient" : "Créer un nouvel article", systemImage: "plus.circle")
                            }
                        }
                        
                        // Afficher les articles par catégorie
                        let filteredCategories = vm.articlesByCategory.filter {
                            selectedCategoryFilter == nil || $0.key == selectedCategoryFilter
                        }
                        
                        ForEach(filteredCategories.keys.sorted(), id: \.self) { category in
                            Section(header: Text(category)) {
                                ForEach(filteredCategories[category] ?? []) { article in
                                    Button {
                                        vm.selectedArticle = article
                                    } label: {
                                        HStack {
                                            Text(article.name)
                                            
                                            Spacer()
                                            
                                            Text(article.unit)
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                            
                                            if vm.selectedArticle?.id == article.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        // Suggestions d'articles similaires
                        if !vm.similarArticleSuggestions.isEmpty {
                            Section(header: Text("Suggestions similaires")) {
                                ForEach(vm.similarArticleSuggestions) { article in
                                    Button {
                                        vm.selectedArticle = article
                                    } label: {
                                        HStack {
                                            Text(article.name)
                                            
                                            Spacer()
                                            
                                            Text(article.unit)
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                            
                                            if vm.selectedArticle?.id == article.id {
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
                    
                    // Options pour l'article sélectionné
                    if let selectedArticle = vm.selectedArticle {
                        VStack(spacing: 16) {
                            Divider()
                            
                            if forRecipeContext {
                                Text("Quantité pour 1 personne")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text("Quantité")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            // Sélecteur de quantité avec boutons + et -
                            HStack {
                                Button(action: {
                                    let step = vm.getStepValue(for: selectedArticle.unit)
                                    quantity = max(step, quantity - step)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                if vm.isDecimalUnit(selectedArticle.unit) {
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
                                    let step = vm.getStepValue(for: selectedArticle.unit)
                                    quantity += step
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Unité de mesure
                            Text(selectedArticle.unit)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            if forRecipeContext {
                                Toggle("Ingrédient optionnel", isOn: $isOptional)
                                    .padding(.horizontal)
                            }
                            
                            Button {
                                onArticleSelected(selectedArticle, quantity, isOptional)
                                dismiss()
                            } label: {
                                Text(forRecipeContext ? "Ajouter à la recette" : "Ajouter à la liste")
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
            // Utilisation d'un titre personnalisé avec un ViewBuilder pour permettre un titre sur deux lignes
            .toolbar {
                ToolbarItem(placement: .principal) {
                    customNavigationTitle
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddNewArticle) {
                if let vm = viewModel {
                    AddNewArticleView(
                        viewModel: vm,
                        forRecipe: forRecipeContext,
                        onArticleCreated: { article in
                            vm.selectedArticle = article
                            vm.fetchArticles()
                        }
                    )
                }
            }
            .onAppear {
                print("ArticleSelectionView appeared")
                if viewModel == nil {
                    viewModel = ArticlesViewModel(modelContext: modelContext)
                    // Initialiser la recherche avec les bons filtres
                    viewModel?.searchArticle(query: "", forRecipe: forRecipeContext)
                }
            }
        }
    }
    
    // Titre de navigation personnalisé qui s'adapte à plusieurs lignes
    private var customNavigationTitle: some View {
        VStack {
            if forRecipeContext, let name = recipeName {
                Text("Ajouter un ingrédient")
                    .font(.headline)
                    .lineLimit(1)
                Text("à \(name)")
                    .font(.subheadline)
                    .lineLimit(1)
            } else if forRecipeContext {
                Text("Ajouter un ingrédient")
                    .font(.headline)
            } else {
                Text("Ajouter un article")
                    .font(.headline)
            }
        }
        .multilineTextAlignment(.center)
    }
}
