import SwiftUI
import SwiftData

struct AddNewArticleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var viewModel: ArticlesViewModel
    var forRecipe: Bool = true
    var onArticleCreated: (Article) -> Void
    
    @State private var name: String = ""
    @State private var category: String = "Fruits et légumes"
    @State private var unit: String = "pièce(s)"
    @State private var isFood: Bool = true
    @State private var showingSimilarArticleAlert = false
    @State private var similarArticle: Article?
    @State private var nameEdited = false
    @State private var attemptedToAdd = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informations de l'article")) {
                    TextField("Nom", text: $name)
                        .onChange(of: name) { oldValue, newValue in
                            nameEdited = true
                            // Vérifier les similitudes dès que le nom change
                            // si l'utilisateur a tapé au moins 3 caractères
                            if newValue.count >= 3 {
                                checkForSimilarArticle()
                            }
                        }
                        .onSubmit {
                            checkForSimilarArticle()
                        }
                    
                    // Type d'article (nourriture ou non)
                    if !forRecipe {
                        Toggle("Article alimentaire", isOn: $isFood)
                            .onChange(of: isFood) { oldValue, newValue in
                                // Ajuster la catégorie si nécessaire
                                if newValue && !viewModel.foodCategories.contains(category) {
                                    category = viewModel.foodCategories.first ?? "Fruits et légumes"
                                } else if !newValue && !viewModel.nonFoodCategories.contains(category) {
                                    category = viewModel.nonFoodCategories.first ?? "Hygiène et beauté"
                                }
                            }
                    }
                    
                    Picker("Catégorie", selection: $category) {
                        ForEach(isFood ? viewModel.foodCategories : viewModel.nonFoodCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .onChange(of: category) { _, _ in
                        if nameEdited && name.count >= 3 {
                            checkForSimilarArticle()
                        }
                    }
                    
                    Picker("Unité", selection: $unit) {
                        ForEach(viewModel.units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .onChange(of: unit) { _, _ in
                        if nameEdited && name.count >= 3 {
                            checkForSimilarArticle()
                        }
                    }
                }
                
                // Suppression de la remarque sur l'article alimentaire en contexte recette
            }
            .navigationTitle(forRecipe ? "Nouvel ingrédient" : "Nouvel article")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        attemptedToAdd = true
                        // Vérifier une dernière fois avant d'ajouter
                        if let similar = viewModel.checkForSimilarArticle(name: name, forRecipe: forRecipe) {
                            similarArticle = similar
                            showingSimilarArticleAlert = true
                        } else {
                            // Aucun doublon, on peut ajouter
                            if let article = addArticle() {
                                onArticleCreated(article)
                                dismiss()
                            }
                        }
                    }
                    .disabled(name.isEmpty || category.isEmpty || unit.isEmpty)
                }
            }
            .alert(isPresented: $showingSimilarArticleAlert) {
                Alert(
                    title: Text("Article similaire trouvé"),
                    message: Text("Vouliez-vous dire \"\(similarArticle?.name ?? "")\"?"),
                    primaryButton: .default(Text("Oui, utiliser existant")) {
                        if let article = similarArticle {
                            // Utiliser l'article existant
                            onArticleCreated(article)
                            dismiss()
                        }
                    },
                    secondaryButton: .cancel(Text("Non, créer nouveau")) {
                        if attemptedToAdd {
                            // L'utilisateur a explicitement refusé la suggestion lors de l'ajout
                            // On force la création d'un nouvel article
                            let newArticle = Article(name: name, category: category, unit: unit, isFood: forRecipe || isFood)
                            modelContext.insert(newArticle)
                            try? modelContext.save()
                            viewModel.fetchArticles()
                            onArticleCreated(newArticle)
                            dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func addArticle() -> Article? {
        // Utilisez le ViewModel pour ajouter l'article
        return viewModel.addArticle(name: name, category: category, unit: unit, isFood: forRecipe || isFood)
    }
    
    private func checkForSimilarArticle() {
        if let similar = viewModel.checkForSimilarArticle(name: name, forRecipe: forRecipe) {
            similarArticle = similar
            showingSimilarArticleAlert = true
            nameEdited = false
        }
    }
}
