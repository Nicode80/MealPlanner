import UIKit

extension UIImage {
    /// Optimise l'image en compressant son format JPEG
    /// Retourne des données compressées garantissant une réduction de taille significative
    func optimizedImageData(quality: CGFloat = 0.7) -> Data? {
        // Obtenir les données originales pour comparaison
        guard let originalData = self.jpegData(compressionQuality: 1.0) else {
            return nil
        }
        
        // Compresser l'image avec la qualité spécifiée
        var currentQuality = quality
        var compressedData = self.jpegData(compressionQuality: currentQuality)
        
        // Si la compression n'a pas suffisamment réduit la taille, essayer des qualités inférieures
        if let data = compressedData {
            // Adapter la qualité si nécessaire pour garantir une réduction de taille
            var attempts = 0
            while data.count >= originalData.count * Int(0.8) && currentQuality > 0.3 && attempts < 3 {
                currentQuality -= 0.1
                attempts += 1
                if let newData = self.jpegData(compressionQuality: currentQuality) {
                    compressedData = newData
                    // Si on atteint une réduction significative, sortir de la boucle
                    if newData.count <= originalData.count * Int(0.6) {
                        break
                    }
                }
            }
        }
        
        // Retourner les données compressées
        if let finalData = compressedData, finalData.count < originalData.count {
            return finalData
        }
        
        return originalData
    }
}
