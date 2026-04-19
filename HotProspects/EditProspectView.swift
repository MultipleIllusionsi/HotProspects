//
//  EditProspectView.swift
//  HotProspects
//
//  Created by Сергей Захаров on 20.04.2026.
//

import SwiftData
import SwiftUI

struct EditProspectView: View {
    @Bindable var prospect: Prospect

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $prospect.name)
                TextField("Email", text: $prospect.emailAddress)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .navigationTitle("Edit prospect")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditProspectView(
            prospect: Prospect(name: "Taylor Swift", emailAddress: "taylor@example.com", isContacted: false)
        )
    }
    .modelContainer(for: Prospect.self, inMemory: true)
}
