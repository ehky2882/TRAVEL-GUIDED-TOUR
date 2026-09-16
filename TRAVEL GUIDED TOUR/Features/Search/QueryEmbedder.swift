import CoreML
import Foundation

/// Turns a typed query into the same 384-dim vector the catalog was built with.
///
/// The catalog's vectors come from `scripts/build-embeddings.py` running
/// all-MiniLM-L6-v2 offline. A query cannot be precomputed — it does not exist
/// until someone types it — so this is the one place the app runs a model at
/// all. "More like this" still runs none: it ships ids.
///
/// 🔴 EVERYTHING HERE EXISTS TO MATCH PYTHON, AND THE MATCH IS TESTED.
/// `scripts/verify-coreml-parity.py` runs the converted model on a real Mac and
/// asserts it ranks the catalog identically to the ONNX pipeline before the
/// model is allowed anywhere near a phone. `TokenizerParityTests` pins the ids.
/// Between them, the two halves of "does the phone agree with the server" are
/// covered — which matters because disagreement is silent: no crash, no log,
/// just worse answers.
///
/// ⚠️ POOLING AND NORMALISATION ARE **INSIDE THE MODEL**, not here. The export
/// folds the masked mean and the L2 normalise into the graph, so this file
/// never reimplements them. That is deliberate: `embed_chunks` is fussy about
/// exactly that arithmetic ("padding must not drag vectors toward zero"), and
/// rewriting it in Swift would be one more thing that can drift unnoticed.
actor QueryEmbedder {

    enum Failure: Error, CustomStringConvertible {
        case modelUnavailable
        case modelMismatch(expected: String, found: String)
        case unexpectedOutput(String)

        var description: String {
            switch self {
            case .modelUnavailable:
                "the query embedding model has not been downloaded"
            case .modelMismatch(let expected, let found):
                "model is \(found), catalog was built with \(expected)"
            case .unexpectedOutput(let why):
                "model output was not usable: \(why)"
            }
        }
    }

    /// Must match `MODEL_ID` in `scripts/build-embeddings.py`, and is checked
    /// against the metadata the export writes into the package.
    static let expectedModelID = "sentence-transformers/all-MiniLM-L6-v2"
    static let dimensions = 384
    /// `MAX_TOKENS` in the Python pipeline. Two slots go to [CLS]/[SEP].
    static let maxTokens = 256

    private let model: MLModel
    private let tokenizer: WordPieceTokenizer

    init(model: MLModel, tokenizer: WordPieceTokenizer) throws {
        // A model whose id disagrees with the catalog produces confident
        // nonsense — every vector plausible, every ranking wrong. Refuse it
        // here rather than discover it in a bad search result.
        let declared = model.modelDescription
            .metadata[MLModelMetadataKey.creatorDefinedKey]
            .flatMap { ($0 as? [String: String])?["atlas.model_id"] }

        if let declared, declared != Self.expectedModelID {
            throw Failure.modelMismatch(expected: Self.expectedModelID, found: declared)
        }
        self.model = model
        self.tokenizer = tokenizer
    }

    // MARK: - Embedding

    /// The unit vector for `text`, or nil when there is nothing to embed.
    ///
    /// ⚠️ ONE WINDOW, matching `Embedder.embed_one`, which returns the FIRST
    /// chunk rather than a mean over chunks. Queries are short, so this is the
    /// same arithmetic in practice — but it is the same *by construction*, not
    /// by luck, and the parity fixture carries an over-long string to prove it.
    func vector(for text: String) throws -> [Float]? {
        let ids = tokenizer.encode(text)
        guard !ids.isEmpty else { return nil }

        let body = ids.prefix(Self.maxTokens - 2)
        let wrapped = [tokenizer.classificationID] + body + [tokenizer.separatorID]

        let shape: [NSNumber] = [1, NSNumber(value: wrapped.count)]
        let inputIDs = try MLMultiArray(shape: shape, dataType: .int32)
        let mask = try MLMultiArray(shape: shape, dataType: .int32)
        for (index, id) in wrapped.enumerated() {
            inputIDs[index] = NSNumber(value: id)
            // Every position is real: this is one window with no padding, so
            // the mask is all ones. Padding only appears in the batched Python
            // path, which is why the masked mean matters there and not here.
            mask[index] = 1
        }

        let output = try model.prediction(from: try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": MLFeatureValue(multiArray: inputIDs),
            "attention_mask": MLFeatureValue(multiArray: mask),
        ]))

        guard let embedding = output.featureValue(for: "embedding")?.multiArrayValue else {
            throw Failure.unexpectedOutput("no 'embedding' feature")
        }
        guard embedding.count == Self.dimensions else {
            throw Failure.unexpectedOutput(
                "\(embedding.count) dims, expected \(Self.dimensions)"
            )
        }

        var vector = [Float](repeating: 0, count: Self.dimensions)
        for index in 0..<Self.dimensions {
            vector[index] = embedding[index].floatValue
        }
        return vector
    }
}
