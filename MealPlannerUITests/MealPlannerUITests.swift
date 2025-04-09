import XCTest

final class MealPlannerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Mettre l'app en mode test pour utiliser une base de données en mémoire
        app.launchArguments = ["-UITesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Code exécuté après chaque test
    }
    
    @MainActor
    func testRecipeListExists() throws {
        // Un test simple pour vérifier que l'onglet Recettes existe et peut être ouvert
        app.tabBars.buttons["Recettes"].tap()
        XCTAssertTrue(app.navigationBars["Mes Recettes"].exists, "L'écran des recettes devrait être visible")
    }
    
    @MainActor
    func testAddNewRecipe() throws {
        // Navigation vers l'onglet Recettes
        app.tabBars.buttons["Recettes"].tap()
        
        // Ajouter une nouvelle recette
        app.navigationBars["Mes Recettes"].buttons["Ajouter"].tap()
        
        // Remplir le formulaire
        let nameTextField = app.textFields["Nom de la recette"]
        if nameTextField.exists {
            nameTextField.tap()
            nameTextField.typeText("Pasta a la norma")
            
            let descriptionTextField = app.textFields["Description (optionnelle)"]
            if descriptionTextField.exists {
                descriptionTextField.tap()
                descriptionTextField.typeText("Une recette italienne classique")
            }
            
            // Créer la recette
            app.buttons["Créer la recette"].tap()
            
            // Vérifier que la recette est créée et visible dans la liste
            XCTAssertTrue(app.staticTexts["Pasta a la norma"].exists)
        } else {
            XCTFail("Le champ de nom de recette n'est pas visible")
        }
    }
    
    @MainActor
    func testCreateEmptyRecipe() throws {
        // Test pour créer une recette sans ingrédients et vérifier qu'elle est marquée comme incomplète
        
        // Navigation vers l'onglet Recettes
        app.tabBars.buttons["Recettes"].tap()
        
        // Ajouter une nouvelle recette
        app.navigationBars["Mes Recettes"].buttons["Ajouter"].tap()
        
        // Remplir le formulaire
        let nameTextField = app.textFields["Nom de la recette"]
        nameTextField.tap()
        nameTextField.typeText("Recette vide")
        
        // Créer la recette sans ingrédients
        app.buttons["Créer la recette"].tap()
        
        // Important: La recette est ouverte automatiquement après création
        // Nous devons donc revenir à la liste des recettes
        
        // Revenir à la liste des recettes en utilisant le bouton back
        let backButton = app.navigationBars.buttons.element(boundBy: 0) // Premier bouton de la barre de navigation
        XCTAssertTrue(backButton.exists, "Le bouton retour devrait être visible")
        backButton.tap()
        
        // Attendre que la liste des recettes apparaisse
        let recipesList = app.navigationBars["Mes Recettes"]
        let listAppears = recipesList.waitForExistence(timeout: 5)
        XCTAssertTrue(listAppears, "La liste des recettes devrait être visible après retour")
        
        // Chercher la recette vide dans la liste
        let recipeCell = app.staticTexts["Recette vide"]
        XCTAssertTrue(recipeCell.exists, "La recette 'Recette vide' devrait être visible dans la liste")
        
        // Maintenant, vérifier si le badge "Incomplet" est présent près de la recette
        // Utiliser une approche par proximité spatiale
        
        // Vérifier directement si le texte "Incomplet" est visible dans l'écran
        let incompleteBadge = app.staticTexts["Incomplet"]
        
        // Prendre une capture d'écran pour le débogage
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
        
        XCTAssertTrue(incompleteBadge.exists, "Le badge 'Incomplet' devrait être visible près de la recette vide")
    }
}
