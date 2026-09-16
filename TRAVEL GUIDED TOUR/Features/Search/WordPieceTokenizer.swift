import Foundation

/// BERT WordPiece, reimplemented, because there is no Apple framework for it.
///
/// 🔴 THIS FILE EXISTS TO AGREE WITH A PYTHON SCRIPT, AND NOTHING ELSE.
/// `scripts/build-embeddings.py` tokenizes the whole catalog with HuggingFace
/// `tokenizers` and ships the resulting vectors. A query typed on the phone is
/// only comparable to those vectors if it is tokenized **identically**. Every
/// rule below mirrors `all-MiniLM-L6-v2`'s `tokenizer.json`:
///
///     normalizer:     BertNormalizer(clean_text, handle_chinese_chars,
///                                    strip_accents: null, lowercase: true)
///     pre_tokenizer:  BertPreTokenizer
///     model:          WordPiece(unk: "[UNK]", max_input_chars_per_word: 100)
///
/// ⚠️ A WRONG TOKENIZER DOES NOT CRASH. It produces slightly different ids, so
/// a slightly different vector, so plausible-looking but worse results — with
/// nothing anywhere reporting it. `SemanticParityTests` is what makes that
/// loud: it pins 58 cases against ids dumped from the real Python tokenizer
/// (`scripts/dump-tokenizer-fixture.py`). **Change nothing here without
/// re-running that test.**
struct WordPieceTokenizer {

    enum Failure: Error, CustomStringConvertible {
        case vocabularyUnreadable(String)
        case vocabularyMissingSpecialToken(String)

        var description: String {
            switch self {
            case .vocabularyUnreadable(let why): "WordPiece vocabulary unreadable: \(why)"
            case .vocabularyMissingSpecialToken(let token):
                "WordPiece vocabulary has no \(token) — wrong vocab file for this model"
            }
        }
    }

    /// `max_input_chars_per_word` from `tokenizer.json`. A longer run of
    /// non-space characters becomes a single `[UNK]` rather than being split,
    /// which is why a 150-character string of `x` is one token and not fifty.
    static let maxInputCharsPerWord = 100

    private let vocabulary: [String: Int32]
    let unknownID: Int32
    let classificationID: Int32     // [CLS]
    let separatorID: Int32          // [SEP]
    let paddingID: Int32            // [PAD]

    var vocabularySize: Int { vocabulary.count }

    /// Builds from a `vocab.txt` — one token per line, id = line number, which
    /// is the format `scripts/export-coreml.py` writes out of `tokenizer.json`.
    init(vocabularyText: String) throws {
        var table: [String: Int32] = [:]
        // `split(omittingEmptySubsequences: false)` matters: an empty line in a
        // BERT vocab is a real token and dropping it would shift every id after
        // it by one — a silent, catalog-wide corruption.
        let lines = vocabularyText.split(separator: "\n", omittingEmptySubsequences: false)
        table.reserveCapacity(lines.count)
        for (index, line) in lines.enumerated() {
            // A trailing newline leaves one empty final element that is not a
            // token; everything before it is.
            if index == lines.count - 1, line.isEmpty { break }
            let token = line.hasSuffix("\r") ? String(line.dropLast()) : String(line)
            if table[token] == nil { table[token] = Int32(index) }
        }
        guard table.count > 1 else {
            throw Failure.vocabularyUnreadable("only \(table.count) token(s) parsed")
        }
        func require(_ token: String) throws -> Int32 {
            guard let id = table[token] else { throw Failure.vocabularyMissingSpecialToken(token) }
            return id
        }
        self.vocabulary = table
        self.unknownID = try require("[UNK]")
        self.classificationID = try require("[CLS]")
        self.separatorID = try require("[SEP]")
        self.paddingID = try require("[PAD]")
    }

    // MARK: - Public entry point

    /// Token ids for `text`, without `[CLS]`/`[SEP]`.
    ///
    /// The caller adds those, because chunking happens on the bare ids and the
    /// specials are re-added per window — exactly as `chunk_ids` does in
    /// `build-embeddings.py`.
    func encode(_ text: String) -> [Int32] {
        var ids: [Int32] = []
        for word in Self.preTokenize(Self.normalize(text)) {
            appendWordPieces(of: word, to: &ids)
        }
        return ids
    }

    // MARK: - Normalizer

    /// `BertNormalizer`, in its real order.
    ///
    /// 🔴 THE ORDER IS LOAD-BEARING and is not the order you would guess:
    /// clean → pad CJK → strip accents → lowercase. Accent stripping runs
    /// BEFORE lowercasing, and it runs at all because `strip_accents` is null,
    /// which in HuggingFace means "follow `lowercase`" — and `lowercase` is
    /// true. Reading the config as "strip_accents: null → don't strip" is the
    /// obvious misreading and it is wrong.
    static func normalize(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()

        // 1. clean_text — drop NULs and control characters, fold whitespace to
        //    a plain space. Tab/newline/CR are whitespace here, not controls.
        for scalar in text.unicodeScalars {
            if scalar.value == 0 || scalar.value == 0xFFFD { continue }
            if isWhitespace(scalar) {
                scalars.append(" ")
            } else if isControl(scalar) {
                continue
            } else {
                scalars.append(scalar)
            }
        }

        // 2. handle_chinese_chars — pad every CJK IDEOGRAPH with spaces so each
        //    becomes its own token.
        //    ⚠️ Ideographs ONLY. Kana and Hangul are deliberately excluded by
        //    BERT's definition, so 東京 tokenizes as two tokens while タワー
        //    goes through ordinary word-piece continuation (タ ##ワ ##ー). The
        //    parity fixture pins both, because getting this backwards is
        //    invisible in English and wrong for 281 catalog titles.
        var padded = String.UnicodeScalarView()
        for scalar in scalars {
            if isCJKIdeograph(scalar) {
                padded.append(" ")
                padded.append(scalar)
                padded.append(" ")
            } else {
                padded.append(scalar)
            }
        }

        // 3. strip_accents — NFD, then drop every non-spacing mark.
        //    ⚠️ This also decomposes Hangul syllables into jamo (아 → ᄋ + ᅡ),
        //    which is why Korean titles tokenize as jamo sequences. That is the
        //    real tokenizer's behaviour, not a bug to "fix".
        let decomposed = String(padded).decomposedStringWithCanonicalMapping
        var stripped = String.UnicodeScalarView()
        for scalar in decomposed.unicodeScalars
        where scalar.properties.generalCategory != .nonspacingMark {
            stripped.append(scalar)
        }

        // 4. lowercase, last.
        return String(stripped).lowercased()
    }

    // MARK: - Pre-tokenizer

    /// `BertPreTokenizer`: split on whitespace, then split punctuation off as
    /// its own token. "st. paul's" → ["st", ".", "paul", "'", "s"].
    static func preTokenize(_ normalized: String) -> [String] {
        var words: [String] = []
        var current = String.UnicodeScalarView()

        func flush() {
            if !current.isEmpty {
                words.append(String(current))
                current = String.UnicodeScalarView()
            }
        }

        for scalar in normalized.unicodeScalars {
            if isWhitespace(scalar) {
                flush()
            } else if isPunctuation(scalar) {
                flush()
                words.append(String(scalar))
            } else {
                current.append(scalar)
            }
        }
        flush()
        return words
    }

    // MARK: - WordPiece

    /// Greedy longest-match-first, with `##` marking a continuation piece.
    ///
    /// ⚠️ The whole word becomes ONE `[UNK]` when any piece fails to match —
    /// not a partial tokenization, and not `[UNK]` per character. Same for a
    /// word over `maxInputCharsPerWord`.
    private func appendWordPieces(of word: String, to ids: inout [Int32]) {
        // 🔴 UNICODE SCALARS, NOT `Character`. Swift's `Character` is a grapheme
        // CLUSTER, so a flag or a family emoji counts as one — while BERT counts
        // code points. `Array(word)` agrees with Python on every case in the
        // parity fixture and silently disagrees on clustered emoji, which
        // link-pin titles are full of. The Python mirror cannot catch this,
        // because Python has no grapheme-cluster string type: only the Swift
        // test can, and only if the fixture carries such a case.
        let scalars = Array(word.unicodeScalars)
        guard !scalars.isEmpty else { return }
        guard scalars.count <= Self.maxInputCharsPerWord else {
            ids.append(unknownID)
            return
        }

        var pieces: [Int32] = []
        var start = 0
        while start < scalars.count {
            var end = scalars.count
            var matched: Int32?
            while start < end {
                var candidate = String(String.UnicodeScalarView(scalars[start..<end]))
                if start > 0 { candidate = "##" + candidate }
                if let id = vocabulary[candidate] {
                    matched = id
                    break
                }
                end -= 1
            }
            guard let id = matched else {
                // Unmatchable: the ENTIRE word is [UNK], and anything matched
                // so far is discarded.
                ids.append(unknownID)
                return
            }
            pieces.append(id)
            start = end
        }
        ids.append(contentsOf: pieces)
    }

    // MARK: - Character classes
    //
    // Mirrors BERT's own helpers rather than Foundation's character sets, which
    // disagree at the edges — `CharacterSet.punctuationCharacters` excludes
    // `+` `<` `=` `>` `$` `^` `` ` `` `|` `~`, all of which BERT treats as
    // punctuation.

    static func isWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x20, 0x09, 0x0A, 0x0D: true
        default: scalar.properties.generalCategory == .spaceSeparator
        }
    }

    static func isControl(_ scalar: Unicode.Scalar) -> Bool {
        // Tab, newline and CR reach this as whitespace, never as controls.
        if scalar.value == 0x09 || scalar.value == 0x0A || scalar.value == 0x0D { return false }
        switch scalar.properties.generalCategory {
        case .control, .format, .surrogate, .privateUse, .unassigned: return true
        default: return false
        }
    }

    /// BERT's rule: the ASCII punctuation blocks plus every Unicode P* category.
    static func isPunctuation(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        if (value >= 33 && value <= 47) || (value >= 58 && value <= 64)
            || (value >= 91 && value <= 96) || (value >= 123 && value <= 126) {
            return true
        }
        switch scalar.properties.generalCategory {
        case .connectorPunctuation, .dashPunctuation, .openPunctuation,
             .closePunctuation, .initialPunctuation, .finalPunctuation,
             .otherPunctuation:
            return true
        default:
            return false
        }
    }

    /// BERT's `_is_chinese_char` — the CJK **ideograph** blocks, verbatim.
    /// Kana (0x3040–0x30FF) and Hangul (0xAC00–0xD7AF) are absent on purpose.
    static func isCJKIdeograph(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x4E00...0x9FFF,     // CJK Unified Ideographs
             0x3400...0x4DBF,     //   Extension A
             0x20000...0x2A6DF,   //   Extension B
             0x2A700...0x2B73F,   //   Extension C
             0x2B740...0x2B81F,   //   Extension D
             0x2B820...0x2CEAF,   //   Extension E
             0xF900...0xFAFF,     // Compatibility Ideographs
             0x2F800...0x2FA1F:   //   Compatibility Supplement
            true
        default:
            false
        }
    }
}
