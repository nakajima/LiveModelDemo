//
//  ContentView.swift
//  LiveModelDemo
//
//  Created by Pat Nakajima on 5/5/24.
//

import SwiftData
import SwiftUI

// The model
@Model final class Person {
	@Attribute(.unique) var name: String
	var friendCount: Int = 0

	init(name: String) {
		self.name = name
	}
}

// Our view that needs to stay up to date
struct PersonView: View {
	// If you remove @LiveModel, the friend count won't be updated by the "Add random friend" button
	@LiveModel var person: Person

	var body: some View {
		HStack {
			Text(person.name)
			Text("\(person.friendCount) friend\(person.friendCount == 1 ? "" : "s")")
		}
	}
}

struct ContentView: View {
	@Query var people: [Person]
	@Environment(\.modelContext) var modelContext

	var body: some View {
		List {
			Section {
				ForEach(people, id: \.name) { person in
					PersonView(person: person)
				}
			}

			// Tapping this button should update the PersonViews in the list above
			Button("Add a random friend") {
				// Get some Sendable things we can use in the Task below
				let container = modelContext.container
				let personID = people.randomElement()!.id

				Task {
					// Use a background task to update the person's friendCount
					let context = ModelContext(container)
					let person = context.model(for: personID) as! Person
					person.friendCount += 1
					try! context.save()
				}
			}
		}
		.onAppear {
			// Get us some sample data
			if people.isEmpty {
				for name in ["Frasier", "Niles", "Daphne", "Martin", "Eddy"] {
					let person = Person(name: name)
					modelContext.insert(person)
					try! modelContext.save()
				}
			}
		}
	}
}

#Preview {
	ContentView()
		.modelContainer(for: Person.self, inMemory: true)
}
