import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// The snippet file — the sentence a search result quotes to explain itself.
///
/// 🔴 THE PAIRING GUARD IS THE POINT OF THIS FILE. Snippet N describes chunk N.
/// A snippet file built from a different catalogue would attach a real,
/// well-formed, completely wrong sentence to every result — plausible,
/// unfalsifiable, and silent. Every rejection test below is guarding against
/// that, not against a crash.
///
/// ⚠️ And every rejection must be SILENT. Snippets explain search; they are not
/// search. A bad file costs the explanation and never the results, so the
/// parser returns nil rather than throwing.
final class SnippetIndexTests: XCTestCase {

    /// Builds the format `write_snippets` in `build-embeddings.py` produces:
    /// magic, version, count, 64-byte model id, count+1 offsets, utf8 blob.
    private func makeFile(
        _ snippets: [String],
        model: String = QueryEmbedder.expectedModelID,
        magic: String = "ATLSNIP1",
        version: UInt32 = 1
    ) -> Data {
        var data = Data(magic.utf8)
        func appendWord(_ value: UInt32) {
            for shift in stride(from: 0, to: 32, by: 8) {
                data.append(UInt8((value >> UInt32(shift)) & 0xFF))
            }
        }
        appendWord(version)
        appendWord(UInt32(snippets.count))
        var name = Array(model.utf8.prefix(64))
        name.append(contentsOf: [UInt8](repeating: 0, count: 64 - name.count))
        data.append(contentsOf: name)

        var blob = Data()
        var offsets: [UInt32] = [0]
        for snippet in snippets {
            blob.append(contentsOf: Array(snippet.utf8))
            offsets.append(UInt32(blob.count))
        }
        for offset in offsets { appendWord(offset) }
        data.append(blob)
        return data
    }

    // MARK: - It reads what the pipeline writes

    func testReadsSnippetsBackInOrder() throws {
        let parsed = try XCTUnwrap(TourEmbeddingStore.parseSnippets(
            makeFile(["The first one.", "", "The third one."]),
            expectedChunks: 3,
            modelID: QueryEmbedder.expectedModelID
        ))
        XCTAssertEqual(parsed.count, 3)
    }

    /// An empty snippet is a real, expected value — about 0.6% of chunks have
    /// no whole sentence to quote. It must occupy its slot so everything after
    /// it still lines up.
    func testAnEmptySnippetKeepsItsSlot() throws {
        let parsed = try XCTUnwrap(TourEmbeddingStore.parseSnippets(
            makeFile(["first.", "", "third."]), expectedChunks: 3,
            modelID: QueryEmbedder.expectedModelID
        ))
        XCTAssertEqual(parsed.count, 3)
        XCTAssertEqual(parsed.bounds.count, 4)
        XCTAssertEqual(parsed.bounds[1], parsed.bounds[2], "the empty one spans no bytes")
    }

    func testHandlesNonLatinText() throws {
        let parsed = try XCTUnwrap(TourEmbeddingStore.parseSnippets(
            makeFile(["都爹利街石階の歴史。", "Ordinary."]), expectedChunks: 2,
            modelID: QueryEmbedder.expectedModelID
        ))
        XCTAssertEqual(parsed.count, 2)
    }

    // MARK: - 🔴 It refuses a pair that might not belong together

    func testRefusesAFileWithADifferentChunkCount() {
        XCTAssertNil(
            TourEmbeddingStore.parseSnippets(
                makeFile(["a.", "b."]),
                expectedChunks: 3,                 // the index has three
                modelID: QueryEmbedder.expectedModelID
            ),
            "a count mismatch means these were built from different catalogues"
        )
    }

    func testRefusesAFileFromADifferentModel() {
        XCTAssertNil(TourEmbeddingStore.parseSnippets(
            makeFile(["a."], model: "some-other/model"),
            expectedChunks: 1, modelID: QueryEmbedder.expectedModelID
        ))
    }

    func testRefusesAFutureFormatVersion() {
        XCTAssertNil(TourEmbeddingStore.parseSnippets(
            makeFile(["a."], version: 2),
            expectedChunks: 1, modelID: QueryEmbedder.expectedModelID
        ))
    }

    func testRefusesSomethingThatIsNotASnippetFile() {
        for junk in [Data(), Data("nope".utf8), makeFile(["a."], magic: "ATLSEMB2")] {
            XCTAssertNil(TourEmbeddingStore.parseSnippets(
                junk, expectedChunks: 1, modelID: QueryEmbedder.expectedModelID
            ))
        }
    }

    /// A truncated download otherwise reads past the end of the blob.
    func testRefusesATruncatedFile() {
        let whole = makeFile(["a long enough snippet to actually truncate."])
        XCTAssertNil(TourEmbeddingStore.parseSnippets(
            Data(whole.prefix(whole.count - 8)), expectedChunks: 1,
            modelID: QueryEmbedder.expectedModelID
        ))
    }
}
