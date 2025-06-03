import SwiftUI

enum MeasurementType_Placeholder: String, Codable {
    case energyBurned = "ENERGY_BURNED"
}

struct WorkoutCard: View {
    let workout: Workout
    let onTap: (() -> Void)?
    
    init(workout: Workout, onTap: (() -> Void)? = nil) {
        self.workout = workout
        self.onTap = onTap
    }
    
    var body: some View {
        // Black background with horizontal layout matching the image
        HStack(spacing: 8) {
            // Left section: Profile image
            VivaProfileImage(
                userId: workout.user.id,
                imageUrl: workout.user.imageUrl,
                size: VivaDesign.Sizing.ProfileImage.mini
            )
            
            // Activity name
            Text(workout.displayName)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(VivaDesign.Typography.pointsTitle)

            Spacer()
            
            // Calories amount
            Text("\(calories) Cals")
                .foregroundColor(VivaDesign.Colors.vivaGreen)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(VivaDesign.Typography.pointsTitle)
            
            // Day of week
            Text(dayOfWeek)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(VivaDesign.Typography.pointsTitle)
                .frame(width: 50)
        }
        .frame(maxWidth: .infinity)
        .padding(0)
        .background(VivaDesign.Colors.surface)
        .onTapGesture {
            if let onTap = onTap {
                onTap()
            }
        }
    }
    
    private var calories: Int {
        workout.measurements
            .first(where: { $0.measurementType.rawValue == MeasurementType_Placeholder.energyBurned.rawValue })?.value ?? 0
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Tue, Wed, etc.
        return formatter.string(from: workout.workoutStartTime)
    }
}
