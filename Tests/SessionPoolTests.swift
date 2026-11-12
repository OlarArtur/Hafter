import Foundation

enum SessionPoolTests {
    static func run() -> Int {
        var failed = 0
        failed += expect("appends a new movie for the contributor", mergeNew())
        failed += expect("dedupes and records both contributors", mergeExisting())
        failed += expect("does not add the same contributor twice", mergeTwice())
        failed += expect("skips a blank id", mergeBlank())
        failed += expect("lists only movies on more than one list", shared())
        failed += expect("everyone contributed", allIn())
        failed += expect("missing contribution", missing())
        return failed
    }

    private static func mergeNew() -> Bool {
        let merged = SessionPool.merge([], incoming: [SessionPool.Incoming(id: "1", title: "A", posterPath: nil, year: "2020")], uid: "u1")
        return merged.count == 1 && merged[0].contributors == ["u1"] && merged[0].title == "A"
    }

    private static func mergeExisting() -> Bool {
        let start = [SessionMovie(id: "1", title: "A", posterPath: "/p", year: "1999", contributors: ["u1"])]
        let merged = SessionPool.merge(start, incoming: [SessionPool.Incoming(id: "1", title: "Other", posterPath: nil, year: nil)], uid: "u2")
        return merged.count == 1
            && merged[0].title == "A"
            && merged[0].contributors == ["u1", "u2"]
            && merged[0].isShared
            && merged[0].sharedLabel == "On 2 lists"
    }

    private static func mergeTwice() -> Bool {
        let start = [SessionMovie(id: "1", title: "A", posterPath: nil, year: nil, contributors: ["u1"])]
        let merged = SessionPool.merge(start, incoming: [SessionPool.Incoming(id: "1", title: "A", posterPath: nil, year: nil)], uid: "u1")
        return merged[0].contributors == ["u1"]
    }

    private static func mergeBlank() -> Bool {
        let merged = SessionPool.merge([], incoming: [SessionPool.Incoming(id: "", title: "Nope", posterPath: nil, year: nil)], uid: "u1")
        return merged.isEmpty
    }

    private static func shared() -> Bool {
        let movies = [
            SessionMovie(id: "1", title: "A", posterPath: nil, year: nil, contributors: ["u1", "u2"]),
            SessionMovie(id: "2", title: "B", posterPath: nil, year: nil, contributors: ["u1"])
        ]
        return SessionPool.sharedMovies(movies).map(\.id) == ["1"]
    }

    private static func allIn() -> Bool {
        SessionPool.everyoneHasContributed(participants: ["a", "b"], contributions: ["a": "foremost", "b": "possibly"])
    }

    private static func missing() -> Bool {
        SessionPool.everyoneHasContributed(participants: ["a", "b"], contributions: ["a": "foremost"]) == false
            && SessionPool.everyoneHasContributed(participants: [], contributions: [:]) == false
    }

    private static func expect(_ name: String, _ passed: Bool) -> Int {
        if passed { return 0 }
        fputs("FAIL \(name)\n", stderr)
        return 1
    }
}

let failures = SessionPoolTests.run()
if failures > 0 {
    fputs("\(failures) failed\n", stderr)
    exit(1)
}
print("SessionPool tests passed")
