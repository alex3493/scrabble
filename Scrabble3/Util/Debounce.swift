//
//  Debounce.swift
//  Scrabble3
//
//  Created by Alex on 1/12/23.
//

import Foundation

class Debounce {
    private let duration: TimeInterval
    private var task: Task<Void, Error>?
    
    init(duration: TimeInterval) {
        self.duration = duration
    }
    
    func submit(operation: @escaping () async -> Void) {
        debounce(operation: operation)
    }
    
    private func debounce(operation: @escaping () async -> Void) {
        task?.cancel()
        
        task = Task {
            try await sleep()
            await operation()
            task = nil
        }
    }
    
    private func sleep() async throws {
        try await Task.sleep(nanoseconds: UInt64(duration * TimeInterval(NSEC_PER_SEC)))
    }
}
