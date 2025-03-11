import SwiftUI

class EditProfileViewModel: ObservableObject {
    @Published var displayName: String
    @Published var email: String
    @Published var caption: String
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let userSession: UserSession
    let userProfileService: UserProfileService

    init(userSession: UserSession, userProfileService: UserProfileService) {
        self.userSession = userSession
        self.userProfileService = userProfileService

        self.displayName = userSession.userProfile?.displayName ?? ""
        self.email = userSession.userProfile?.emailAddress ?? ""
        self.caption = userSession.userProfile?.caption ?? ""
    }

    @MainActor
    func saveProfile() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updateRequest = UserProfileUpdateRequest(
                emailAddress: self.email,
                displayName: self.displayName,
                caption: self.caption)
            let savedUserProfile =
                try await userProfileService.saveCurrentUserProfile(
                    updateRequest, selectedImage)

            self.userSession.setUserProfile(savedUserProfile)
            // Update successful
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating profile. Please try again."
            isLoading = false
            return false
        }
    }
}

struct EditProfileView: View {
    private let captionLengthLimit = 150

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel
    @State private var showImagePicker = false

    private let userProfileService: UserProfileService

    init(userSession: UserSession, userProfileService: UserProfileService) {
        _viewModel = StateObject(
            wrappedValue: EditProfileViewModel(
                userSession: userSession, userProfileService: userProfileService
            ))
        self.userProfileService = userProfileService
    }

    private var limitedCaption: Binding<String> {
        Binding(
            get: { viewModel.caption },
            set: {
                viewModel.caption = String(
                    $0.prefix(captionLengthLimit).replacingOccurrences(
                        of: "\n", with: ""))
            }
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                VivaDesign.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: VivaDesign.Spacing.large) {
                    // Profile Image
                    profileImageSection

                    // Form Fields
                    VStack(spacing: VivaDesign.Spacing.medium) {
                        // Display Name Field
                        TextField("", text: $viewModel.displayName)
                            .placeholder(when: viewModel.displayName.isEmpty) {
                                Text("Display Name")
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText)
                            }
                            .textFieldStyle(VivaTextFieldStyle())

                        // Email Field
                        TextField("", text: $viewModel.email)
                            .placeholder(when: viewModel.email.isEmpty) {
                                Text("Email")
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText)
                            }
                            .textFieldStyle(VivaTextFieldStyle())
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)

                        // Caption Field - Multi-line with text wrapping
                        ZStack(alignment: .topLeading) {
                            if viewModel.caption.isEmpty {
                                Text("Caption")
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                            }

                            TextEditor(text: limitedCaption)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(VivaDesign.Colors.primaryText)
                                .frame(height: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: VivaDesign.Sizing
                                            .cornerRadius
                                    )
                                    .stroke(
                                        VivaDesign.Colors.divider,
                                        lineWidth: VivaDesign.Sizing.borderWidth
                                    )
                                )

                            HStack {
                                Spacer()
                                Text("\(viewModel.caption.count)/\(captionLengthLimit)")
                                    .font(Font.system(size: 12))
                                    .foregroundColor(
                                        VivaDesign.Colors.secondaryText
                                    )
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal, VivaDesign.Spacing.large)

                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(VivaDesign.Typography.caption)
                    }

                    Spacer()

                    // Save Button
                    saveButton
                        .padding(.horizontal, VivaDesign.Spacing.large)
                }
                .padding(.vertical, VivaDesign.Spacing.medium)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(VivaDesign.Colors.primaryText)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Edit Profile")
                        .font(VivaDesign.Typography.header)
                        .foregroundColor(VivaDesign.Colors.primaryText)
                }
            }
        }
    }

    private var profileImageSection: some View {
        VStack(spacing: VivaDesign.Spacing.small) {
            ZStack {
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: VivaDesign.Sizing.ProfileImage.large
                                .rawValue,
                            height: VivaDesign.Sizing.ProfileImage.large
                                .rawValue
                        )
                        .clipShape(Circle())
                } else {
                    VivaProfileImage(
                        userId: viewModel.userSession.userProfile?.id,
                        imageUrl: viewModel.userSession.userProfile?.imageUrl
                            ?? "profile_default", size: .large)
                }

                // Camera icon overlay
                Circle()
                    .fill(VivaDesign.Colors.vivaGreen)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 15))
                    )
                    .offset(x: 25, y: 25)
            }

            Button(action: { showImagePicker = true }) {
                Text("Change Photo")
                    .font(VivaDesign.Typography.caption)
                    .foregroundColor(VivaDesign.Colors.vivaGreen)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage)
        }
    }

    private var saveButton: some View {
        Button(action: {
            Task {
                if await viewModel.saveProfile() {
                    dismiss()
                }
            }
        }) {
            ZStack {
                HStack {
                    Text("Save Changes")
                        .font(VivaDesign.Typography.body.bold())
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(
                        cornerRadius: VivaDesign.Sizing.buttonCornerRadius
                    )
                    .fill(VivaDesign.Colors.vivaGreen)
                )

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.black)
                }
            }
        }
        .disabled(viewModel.isLoading)
    }
}

// Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController, context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate,
        UINavigationControllerDelegate
    {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController
                .InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
