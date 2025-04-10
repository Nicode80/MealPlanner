import SwiftUI

/// Vue pour afficher les résultats de l'optimisation d'une image
struct OptimizationResultView: View {
    let originalData: Data?
    let originalSize: CGSize
    let optimizedData: Data?
    let optimizedSize: CGSize
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Résultats d'optimisation")
                .font(.headline)
            
            if let originalData = originalData, let optimizedData = optimizedData {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Image originale:")
                            .fontWeight(.semibold)
                        
                        if let image = UIImage(data: originalData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            Text("• Taille: \(formatBytes(originalData.count))")
                            Spacer()
                            Text("• Dimensions: \(Int(originalSize.width)) × \(Int(originalSize.height))")
                        }
                        .font(.caption)
                        
                        Divider()
                        
                        Text("Image optimisée:")
                            .fontWeight(.semibold)
                        
                        if let image = UIImage(data: optimizedData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            Text("• Taille: \(formatBytes(optimizedData.count))")
                            Spacer()
                            Text("• Dimensions: \(Int(optimizedSize.width)) × \(Int(optimizedSize.height))")
                        }
                        .font(.caption)
                        
                        let reduction = 100.0 - (Double(optimizedData.count) * 100.0 / Double(originalData.count))
                        HStack {
                            Text("• Réduction: \(formatReduction(reduction))")
                                .fontWeight(.bold)
                                .foregroundColor(reduction > 0 ? .green : .red)
                            
                            Spacer()
                            
                            Image(systemName: reduction > 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundColor(reduction > 0 ? .green : .red)
                        }
                        .padding(.top, 4)
                        
                        if reduction < 0 {
                            Text("Note: L'image optimisée est plus grande que l'originale. Cela peut arriver avec certains formats d'image ou certaines compressions.")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Données d'image non disponibles")
                    .foregroundColor(.secondary)
            }
            
            Button("Fermer") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
    
    /// Formate la taille en bytes pour l'affichage
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Formate le pourcentage de réduction
    private func formatReduction(_ value: Double) -> String {
        return String(format: "%.1f%%", abs(value))
    }
}

#Preview {
    // Créer des données d'exemple pour la prévisualisation
    let originalData = UIImage(systemName: "photo")?.pngData()
    let optimizedData = UIImage(systemName: "photo")?.jpegData(compressionQuality: 0.7)
    
    return OptimizationResultView(
        originalData: originalData,
        originalSize: CGSize(width: 300, height: 200),
        optimizedData: optimizedData,
        optimizedSize: CGSize(width: 200, height: 133)
    )
}
