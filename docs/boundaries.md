# Version 0.1.0 boundaries

All processing is in memory. Snapshots store source documents and rebuild postings on load. CJK matching is character based, without a dictionary segmenter. No wildcard, fuzzy search or stemming. Highlight ranges use Unicode code-point offsets and identify positive query terms, not complete phrase spans; they are data rather than HTML. Results use Double scores; displayed serialised scores may round to the same value.
