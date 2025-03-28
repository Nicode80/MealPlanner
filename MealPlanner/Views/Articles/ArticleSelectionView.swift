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
    @State private var scrollToNewArticle: Bool = false
    
    let forRecipeContext: Bool
    let recipeName: String?
    let onArticleSelected: (Article, Double, Bool) -> Void
    
    init(forRecipe: Bool = true, recipeName: String? = nil, onArticleSelected: @escaping (Article, Double, Bool) -> Void) {
        self.forRecipeContext = forRecipe
        self.recipeName = recipeName
        self.onArticleSelected = onArticleSelected
    }
    
    var body: some View {
        NavigationView {
            if let vm = viewModel {
                // Vue simplifiée
                VStack {
                    // Barre de recherche
                    TextField("Rechercher un article", text: Binding(
                        get: { vm.searchText },
                        set: { vm.searchArticle(query: $0, forRecipe: forRecipeContext) }
                    ))
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Sélecteur de catégorie ultra simplifié
                    if !vm.getCategories(forRecipe: forRecipeContext).isEmpty {
                        Picker("Catégorie", selection: $selectedCategoryFilter) {
                            Text("Toutes les catégories").tag(nil as String?)
                            ForEach(vm.getCategories(forRecipe: forRecipeContext), id: \.self) { category in
                                Text(category).tag(category as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)
                    }
                    
                    // Liste simple
                    SimpleArticleList(
                        viewModel: vm,
                        forRecipeContext: forRecipeContext,
                        selectedCategoryFilter: selectedCategoryFilter,
                        showingAddNewArticle: $showingAddNewArticle
                    )
                    
                    // Partie inférieure - sélecteur de quantité
                    if let selectedArticle = vm.selectedArticle {
                        SimpleQuantitySelector(
                            article: selectedArticle,
                            quantity: $quantity,
                            isOptional: $isOptional,
                            isForRecipe: forRecipeContext,
                            viewModel: vm
                        ) {
                            onArticleSelected(selectedArticle, quantity, isOptional)
                            dismiss()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if forRecipeContext, let name = recipeName {
                            VStack {
                                Text("Ajouter un ingrédient").font(.headline)
                                Text("à \(name)").font(.subheadline)
                            }
                        } else {
                            Text(forRecipeContext ? "Ajouter un ingrédient" : "Ajouter un article")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Annuler") {
                            dismiss()
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .sheet(isPresented: $showingAddNewArticle) {
            if let vm = viewModel {
                AddNewArticleView(
                    viewModel: vm,
                    forRecipe: forRecipeContext,
                    onArticleCreated: { article in
                        vm.selectedArticle = article
                        vm.fetchArticles()
                        selectedCategoryFilter = article.category
                    }
                )
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ArticlesViewModel(modelContext: modelContext)
                viewModel?.searchArticle(query: "", forRecipe: forRecipeContext)
            }
        }
    }
}

struct SimpleArticleList: View {
    let viewModel: ArticlesViewModel
    let forRecipeContext: Bool
    let selectedCategoryFilter: String?
    @Binding var showingAddNewArticle: Bool
    
    var body: some View {
        List {
            // Option pour créer un nouvel article
            Button {
                viewModel.searchText = ""
                showingAddNewArticle = true
            } label: {
                Label(forRecipeContext ? "Créer un nouvel ingrédient" : "Créer un nouvel article", systemImage: "plus.circle")
            }
            
            // Articles filtrés par catégorie
            ForEach(getFilteredArticles(), id: \.id) { article in
                Button {
                    viewModel.selectedArticle = article
                } label: {
                    HStack {
                        Text(article.name)
                        Spacer()
                        Text(article.unit)
                            .foregroundColor(.secondary)
                            .font(.caption)
                        if viewModel.selectedArticle?.id == article.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    // Obtenir les articles filtrés pour simplifier
    private func getFilteredArticles() -> [Article] {
        let allArticles = forRecipeContext ? viewModel.getFoodArticles() : viewModel.articles
        
        if let category = selectedCategoryFilter {
            return allArticles.filter { $0.category == category }
        } else {
            return allArticles
        }
    }
}

struct SimpleQuantitySelector: View {
    let article: Article
    @Binding var quantity: Double
    @Binding var isOptional: Bool
    let isForRecipe: Bool
    let viewModel: ArticlesViewModel
    let onAddPressed: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            Text(isForRecipe ? "Quantité pour 1 personne" : "Quantité")
                .font(.headline)
            
            // Sélecteur de quantité simplifié
            HStack {
                Button { decrementQuantity() } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.blue)
                }
                
                if viewModel.isDecimalUnit(article.unit) {
                    TextField("", value: $quantity, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                } else {
                    TextField("", value: $quantity, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                }
                
                Button { incrementQuantity() } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            Text(article.unit)
                .foregroundColor(.secondary)
            
            if isForRecipe {
                Toggle("Ingrédient optionnel", isOn: $isOptional)
                    .padding(.horizontal)
            }
            
            Button(action: onAddPressed) {
                Text(isForRecipe ? "Ajouter à la recette" : "Ajouter à la liste")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
        .background(Color(.systemBackground))
    }
    
    private func incrementQuantity() {
        let step = viewModel.getStepValue(for: article.unit)
        quantity += step
    }
    
    private func decrementQuantity() {
        let step = viewModel.getStepValue(for: article.unit)
        quantity = max(step, quantity - step)
    }
}
