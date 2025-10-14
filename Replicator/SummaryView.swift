//
//  SummaryView.swift
//  Replicator
//
//  Created by leslie on 10/11/25.
//  Copyright © 2025 Jamf. All rights reserved.
//

import SwiftUI

struct SummaryView: View {
    let theSummary: [String: [String: Int]]
    let theSummaryDetail: [String: [String: [String]]]
    
    @State private var selectedCategory: String?
    @State private var selectedType: String?
    @State private var showPopup = false
    @State private var popupPosition = CGPoint(x: 300, y: 200)
    @State private var popupSize = CGSize(width: 400, height: 300)
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if theSummary.isEmpty {
                    Text("No Results")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    TableHeader()
                        .background(Color(red: 0.36, green: 0.47, blue: 0.58))
                        .padding(.bottom, 1)
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sortedKeys, id: \.self) { key in
                                if key != "computergroups",
                                   key != "mobiledevicegroups",
                                   key != "usergroups",
                                   let values = theSummary[key] {
                                    SummaryRow(
                                        endpoint: key.readable,
                                        createCount: values["create"] ?? 0,
                                        updateCount: values["update"] ?? 0,
                                        failCount: values["fail"] ?? 0,
                                        onShowDetails: { type in
                                            selectedCategory = key
                                            selectedType = type
                                            showPopup = true
                                        }
                                    )
                                    Divider()
                                        .background(Color(nsColor: .separatorColor))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 400)
            .background(Color(nsColor: .windowBackgroundColor))
            
            // Floating popup overlay
            if showPopup, let key = selectedCategory, let type = selectedType {
                DraggableResizablePopup(
                    title: "\(key.readable) \(type.capitalized)",
                    items: theSummaryDetail[key]?[type] ?? [],
                    position: $popupPosition,
                    size: $popupSize,
                    onClose: { showPopup = false }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showPopup)
    }
    
    private var sortedKeys: [String] {
        theSummary.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

// MARK: - Header + Rows

private struct TableHeader: View {
    var body: some View {
        HStack {
            Text("Endpoint").frame(maxWidth: .infinity, alignment: .trailing)
            Text(WipeData.state.on ? "Delete" : "Created").frame(width: 90, alignment: .trailing)
            Text("Updated").frame(width: 90, alignment: .trailing)
            Text("Failed").frame(width: 90, alignment: .trailing)
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

private struct SummaryRow: View {
    let endpoint: String
    let createCount: Int
    let updateCount: Int
    let failCount: Int
    let onShowDetails: (String) -> Void
    
    var body: some View {
        HStack {
            Text(endpoint)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            CountButton(label: "\(createCount)", color: .green) { onShowDetails("create") }
            CountButton(label: "\(updateCount)", color: .blue) { onShowDetails("update") }
            CountButton(label: "\(failCount)", color: .red) { onShowDetails("fail") }
        }
        .font(.system(size: 13))
        .padding(.vertical, 4)
    }
}

private struct CountButton: View {
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .frame(width: 80, alignment: .trailing)
                .padding(4)
                .foregroundColor(.white)
                .background(color.opacity(0.6))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.push() }
            else { NSCursor.pop() }
        }
    }
}

// MARK: - Draggable & Resizable Popup

private struct DraggableResizablePopup: View {
    let title: String
    let items: [String]
    @Binding var position: CGPoint
    @Binding var size: CGSize
    var onClose: () -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var resizeOffset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar (draggable)
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(Color(red: 0.36, green: 0.47, blue: 0.58))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        position.x += gesture.translation.width
                        position.y += gesture.translation.height
                    }
            )
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }), id: \.self) { item in
                        Text("• \(item)")
                            .font(.system(size: 13))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
            
            Divider()
            
            // Resize handle (bottom-right corner)
            HStack {
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10))
                    .padding(6)
                    .foregroundColor(.secondary)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                size.width += gesture.translation.width
                                size.height += gesture.translation.height
                            }
                    )
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 10)
        .position(position)
        .animation(.easeInOut(duration: 0.2), value: position)
    }
}


