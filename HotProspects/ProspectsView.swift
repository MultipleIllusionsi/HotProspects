//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Сергей Захаров on 19.04.2026.
//

import CodeScanner
import SwiftData
import SwiftUI
import UserNotifications
internal import AVFoundation

private enum ProspectSortOrder: String, CaseIterable {
    case name
    case recent

    var menuLabel: String {
        switch self {
        case .name: "Name"
        case .recent: "Most recent"
        }
    }

    var sortDescriptors: [SortDescriptor<Prospect>] {
        switch self {
        case .name:
            [SortDescriptor(\Prospect.name)]
        case .recent:
            [SortDescriptor(\Prospect.createdAt, order: .reverse)]
        }
    }
}

struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }

    @AppStorage("prospectSortOrder") private var sortOrderRaw = ProspectSortOrder.name.rawValue
    let filter: FilterType

    private var sortOrder: ProspectSortOrder {
        ProspectSortOrder(rawValue: sortOrderRaw) ?? .name
    }

    var body: some View {
        ProspectsListContent(filter: filter, sortOrder: sortOrder, sortOrderRaw: $sortOrderRaw)
            .id(sortOrder)
    }

    init(filter: FilterType) {
        self.filter = filter
    }
}

private struct ProspectsListContent: View {
    @Query var prospects: [Prospect]
    @Environment(\.modelContext) var modelContext
    @State private var selectedProspects = Set<Prospect>()
    @State private var isShowingScanner = false

    let filter: ProspectsView.FilterType
    @Binding var sortOrderRaw: String

    var title: String {
        switch filter {
        case .none:
            "Everyone"
        case .contacted:
            "Contacted people"
        case .uncontacted:
            "Uncontacted people"
        }
    }

    var body: some View {
        NavigationStack {
            List(prospects, selection: $selectedProspects) { prospect in
                NavigationLink {
                    EditProspectView(prospect: prospect)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        if filter == .none {
                            Image(systemName: prospect.isContacted ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark")
                                .font(.title2)
                                .foregroundStyle(prospect.isContacted ? .green : .secondary)
                                .accessibilityLabel(prospect.isContacted ? "Contacted" : "Not contacted")
                        }
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        modelContext.delete(prospect)
                    }

                    if prospect.isContacted {
                        Button("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark") {
                            prospect.isContacted.toggle()
                        }
                        .tint(.blue)
                    } else {
                        Button("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark") {
                            prospect.isContacted.toggle()
                        }
                        .tint(.green)

                        Button("Remind Me", systemImage: "bell") {
                            addNotification(for: prospect)
                        }
                        .tint(.orange)
                    }
                }
                .tag(prospect)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        Picker("Sort by", selection: $sortOrderRaw) {
                            ForEach(ProspectSortOrder.allCases, id: \.rawValue) { order in
                                Text(order.menuLabel).tag(order.rawValue)
                            }
                        }
                    }

                    Button("Scan", systemImage: "qrcode.viewfinder") {
                        isShowingScanner = true
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                if selectedProspects.isEmpty == false {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Selected", action: delete)
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: handleScan)
            }
        }
        .toolbar(selectedProspects.isEmpty ? .automatic : .hidden, for: .tabBar)
    }

    init(filter: ProspectsView.FilterType, sortOrder: ProspectSortOrder, sortOrderRaw: Binding<String>) {
        self.filter = filter
        _sortOrderRaw = sortOrderRaw

        let descriptors = sortOrder.sortDescriptors

        if filter != .none {
            let showContactedOnly = filter == .contacted

            _prospects = Query(filter: #Predicate {
                $0.isContacted == showContactedOnly
            }, sort: descriptors)
        } else {
            _prospects = Query(sort: descriptors)
        }
    }

    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false

        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }

            let person = Prospect(name: details[0], emailAddress: details[1], isContacted: false)

            modelContext.insert(person)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }

    func delete() {
        for prospect in selectedProspects {
            modelContext.delete(prospect)
        }
    }

    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

//            var dateComponents = DateComponents()
//            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else if let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    ProspectsView(filter: .none)
        .modelContainer(for: Prospect.self)
}
