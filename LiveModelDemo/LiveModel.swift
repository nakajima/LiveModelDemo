//
//  LiveModel.swift
//  LiveModelDemo
//
//  Created by Pat Nakajima on 5/5/24.
//

import Combine
import SwiftData
import SwiftDataKit
import NotificationCenter
import CoreData

// Keep a SwiftData record up to date
@propertyWrapper @Observable public final class LiveModel<T: PersistentModel> {
	var _model: T

	@MainActor public var wrappedValue: T {
		get { _model }
		set { _model = newValue }
	}

	var cancellable: AnyCancellable?

	@MainActor public init(wrappedValue: T) {
		self._model = wrappedValue

		if let context = wrappedValue.modelContext {
			self.cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave).sink { [weak self] notification in
				guard let userInfo = notification.userInfo, let self else {
					return
				}

				if let updated = userInfo["updated"],
					 // Convert to an actual swift set
					 let set = (updated as? NSSet as? Set<NSManagedObject>),
					 // See if this update is for our model
					 let object = set.first(where: { $0.objectID.persistentIdentifier == self._model.id }),
					 // We know we have a persistent identifier because of the above check, so try to reload
					 // our model from its context.
					 let model: T = context.registeredModel(for: object.objectID.persistentIdentifier!)
				{
					// Update our model, so the Observation system can let the view know.
					self._model = model
				}
			}
		}
	}

	deinit {
		cancellable?.cancel()
	}
}
