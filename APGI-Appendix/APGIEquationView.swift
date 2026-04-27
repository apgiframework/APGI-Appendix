import SwiftUI

struct APGIEquationView: View {
    var fontSize: CGFloat = 24
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Π")
                .foregroundColor(.precisionRed)
            
            Text("×")
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                Text("|")
                    .foregroundColor(.secondary)
                Text("ε")
                    .foregroundColor(.errorYellow)
                Text("|")
                    .foregroundColor(.secondary)
            }
            
            Text(">")
                .foregroundColor(.secondary)
            
            Text("Bₜ")
                .foregroundColor(.thresholdBlue)
        }
        .font(.custom("CrimsonPro-Bold", size: fontSize))
        // Fallback for when Crimson Pro is not loaded
        .font(.system(size: fontSize, weight: .bold, design: .serif))
    }
}

#Preview {
    ZStack {
        Color.spaceBlack.ignoresSafeArea()
        APGIEquationView(fontSize: 48)
    }
}
