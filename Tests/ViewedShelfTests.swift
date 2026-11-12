import Foundation

enum ViewedShelfTests {
    static func run() -> Int {
        var failed = 0
        failed += expect("clamps rating", ViewedShelf.clampRating(0) == 1 && ViewedShelf.clampRating(9) == 5 && ViewedShelf.clampRating(3) == 3)
        failed += expect("sorts newest first", sort())
        failed += expect("caption", ViewedShelf.caption(rating: 4, date: nil) == "4/5")
        failed += expect("empty caption", ViewedShelf.caption(rating: nil, date: nil) == nil)
        return failed
    }

    private static func sort() -> Bool {
        let older = Date(timeIntervalSince1970: 10)
        let newer = Date(timeIntervalSince1970: 20)
        let items = [
            ViewedShelf.Item(id: "b", watchedDate: older, rating: 2),
            ViewedShelf.Item(id: "a", watchedDate: newer, rating: 5),
            ViewedShelf.Item(id: "c", watchedDate: nil, rating: nil)
        ]
        return ViewedShelf.sorted(items).map(\.id) == ["a", "b", "c"]
    }

    private static func expect(_ name: String, _ passed: Bool) -> Int {
        if passed { return 0 }
        fputs("FAIL \(name)\n", stderr)
        return 1
    }
}

let failures = ViewedShelfTests.run()
if failures > 0 {
    fputs("\(failures) failed\n", stderr)
    exit(1)
}
print("ViewedShelf tests passed")
