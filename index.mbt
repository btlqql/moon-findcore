///|
pub(all) struct TextToken {
  term : String
  position : Int
  start : Int
  end : Int
} derive(Eq)

///|
pub fn analyze(source : String) -> Array[TextToken] {
  let tokens : Array[TextToken] = []
  let chars = source.to_array()
  let mut word = ""
  let mut word_start = 0
  for i = 0; i <= chars.length(); i = i + 1 {
    let c = if i == chars.length() { ' ' } else { chars[i] }
    let code = c.to_int()
    let cjk = code >= 0x4e00 && code <= 0x9fff
    let word_char = (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '_' ||
      (code >= 0x00c0 && code <= 0x02af)
    if word_char {
      if word == "" {
        word_start = i
      }
      word += c.to_string()
    } else {
      if word != "" {
        tokens.push({
          term: word.to_lower(),
          position: tokens.length(),
          start: word_start,
          end: i,
        })
        word = ""
      }
      if cjk {
        tokens.push({
          term: c.to_string(),
          position: tokens.length(),
          start: i,
          end: i + 1,
        })
      }
    }
  }
  tokens
}

///|
pub struct SearchIndex {
  documents : Map[String, Value]
  postings : Map[String, Map[String, Array[Int]]]
  lengths : Map[String, Map[String, Int]]
  totals : Map[String, Int]
  fields : Array[String]
}

///|
pub fn build_index(
  documents : Array[Value],
  fields : Array[String],
) -> SearchIndex raise {
  if fields.is_empty() {
    raise InputError("index fields cannot be empty")
  }
  let seen_fields : Map[String, Bool] = {}
  for field in fields {
    if field == "" || field.contains(":") || seen_fields.contains(field) {
      raise InputError("invalid or duplicate field")
    }
    seen_fields[field] = true
  }
  let index : SearchIndex = {
    documents: Map([]),
    postings: Map([]),
    lengths: Map([]),
    totals: Map([]),
    fields,
  }
  for document in documents {
    let id = str(get(document, "id"))
    if id == "" || index.documents.contains(id) {
      raise InputError("empty or duplicate document ID")
    }
    ignore(obj(get(document, "fields")))
    index.documents[id] = document
    for field in fields {
      let text = optional_str(get(get(document, "fields"), field), "")
      let tokens = analyze(text)
      let lengths = index.lengths.get(field).unwrap_or(Map([]))
      lengths[id] = tokens.length()
      index.lengths[field] = lengths
      index.totals[field] = index.totals.get(field).unwrap_or(0) +
        tokens.length()
      for token in tokens {
        let key = field + ":" + token.term
        let posting = index.postings.get(key).unwrap_or(Map([]))
        let positions = posting.get(id).unwrap_or([])
        positions.push(token.position)
        posting[id] = positions
        index.postings[key] = posting
      }
    }
  }
  index
}

///|
pub fn SearchIndex::snapshot(self : SearchIndex) -> Value {
  let ids = self.documents.keys().collect()
  ids.sort()
  record([
    ("version", Number(1.0)),
    ("analyzer", String("latin-words-cjk-unigrams-v1")),
    ("fields", strings(self.fields)),
    ("documents", Array(ids.map(fn(id) { self.documents[id] }))),
  ])
}

///|
fn SearchIndex::term_scores(
  self : SearchIndex,
  term : String,
  fields : Array[String],
  k1 : Double,
  b : Double,
) -> Map[String, Double] raise {
  let scores : Map[String, Double] = {}
  let n = self.documents.length().to_double()
  if n == 0.0 {
    return scores
  }
  for field in fields {
    if !self.fields.contains(field) {
      raise InputError("unknown search field: " + field)
    }
    match self.postings.get(field + ":" + term) {
      None => ()
      Some(posting) => {
        let df = posting.length().to_double()
        let idf = @math.ln(1.0 + (n - df + 0.5) / (df + 0.5))
        let avgdl = self.totals[field].to_double() / n
        for id, positions in posting {
          let tf = positions.length().to_double()
          let dl = self.lengths[field][id].to_double()
          let score = idf *
            tf *
            (k1 + 1.0) /
            (tf + k1 * (1.0 - b + b * dl / avgdl))
          scores[id] = scores.get(id).unwrap_or(0.0) + score
        }
      }
    }
  }
  scores
}

///|
pub(all) enum Query {
  Term(String?, String)
  Phrase(String?, Array[String])
  And(Query, Query)
  Or(Query, Query)
  Not(Query)
}

///|
struct QueryParser {
  tokens : Array[String]
  mut cursor : Int
}

///|
fn query_tokens(source : String) -> Array[String] raise InputError {
  let tokens : Array[String] = []
  let mut token = ""
  let mut quoted = false
  for c in source {
    if quoted {
      token += c.to_string()
      if c == '"' {
        tokens.push(token)
        token = ""
        quoted = false
      }
    } else if c == '"' {
      if token != "" {
        tokens.push(token)
      }
      token = "\""
      quoted = true
    } else if c == '(' || c == ')' {
      if token != "" {
        tokens.push(token)
        token = ""
      }
      tokens.push(c.to_string())
    } else if c == ' ' || c == '\n' || c == '\t' {
      if token != "" {
        tokens.push(token)
        token = ""
      }
    } else {
      token += c.to_string()
    }
  }
  if quoted {
    raise InputError("unterminated query phrase")
  }
  if token != "" {
    tokens.push(token)
  }
  tokens
}

///|
fn QueryParser::peek(self : QueryParser) -> String {
  if self.cursor == self.tokens.length() {
    ""
  } else {
    self.tokens[self.cursor]
  }
}

///|
fn QueryParser::take(self : QueryParser) -> String raise InputError {
  let next = self.peek()
  if next == "" {
    raise InputError("missing query operand")
  }
  self.cursor += 1
  next
}

///|
fn QueryParser::atom(self : QueryParser, depth : Int) -> Query raise {
  if depth > 64 {
    raise InputError("query nesting limit")
  }
  let token = self.take()
  if token == "NOT" {
    return Not(self.atom(depth + 1))
  }
  if token == "(" {
    let query = self.expression(1, depth + 1)
    if self.take() != ")" {
      raise InputError("expected closing parenthesis")
    }
    return query
  }
  if [")", "AND", "OR"].contains(token) {
    raise InputError("unexpected query operator")
  }
  let (field, text) = match token.split_once(":") {
    Some((field, text)) =>
      (
        Some(field.to_string()),
        if text.is_empty() {
          self.take()
        } else {
          text.to_string()
        },
      )
    None => (None, token)
  }
  let terms = analyze(text).map(fn(t) { t.term })
  if terms.is_empty() {
    raise InputError("query has no searchable terms")
  }
  if text.has_prefix("\"") || terms.length() > 1 {
    Phrase(field, terms)
  } else {
    Term(field, terms[0])
  }
}

///|
fn QueryParser::expression(
  self : QueryParser,
  minimum : Int,
  depth : Int,
) -> Query raise {
  let mut left = self.atom(depth)
  while self.peek() != "" && self.peek() != ")" {
    let explicit = self.peek() == "OR" || self.peek() == "AND"
    let precedence = if self.peek() == "OR" { 1 } else { 2 }
    if precedence < minimum {
      break
    }
    let op = if explicit { self.take() } else { "AND" }
    let right = self.expression(precedence + 1, depth + 1)
    left = if op == "OR" { Or(left, right) } else { And(left, right) }
  }
  left
}

///|
pub fn parse_query(source : String) -> Query raise {
  let parser : QueryParser = { tokens: query_tokens(source), cursor: 0, }
  let result = parser.expression(1, 0)
  if parser.peek() != "" {
    raise InputError("unexpected closing parenthesis")
  }
  result
}

///|
fn SearchIndex::evaluate(
  self : SearchIndex,
  query : Query,
  k1 : Double,
  b : Double,
) -> Map[String, Double] raise {
  match query {
    Term(field, term) =>
      self.term_scores(
        term,
        match field {
          Some(f) => [f]
          None => self.fields
        },
        k1,
        b,
      )
    Phrase(field, terms) => {
      let fields = match field {
        Some(f) => [f]
        None => self.fields
      }
      let result : Map[String, Double] = {}
      for field in fields {
        let first = self.term_scores(terms[0], [field], k1, b)
        for id, score in first {
          let positions = self.postings[field + ":" + terms[0]][id]
          let matched = positions.any(fn(start) {
            for i = 1; i < terms.length(); i = i + 1 {
              match self.postings.get(field + ":" + terms[i]) {
                None => return false
                Some(posting) =>
                  match posting.get(id) {
                    None => return false
                    Some(p) => if !p.contains(start + i) { return false }
                  }
              }
            }
            true
          })
          if matched {
            result[id] = result.get(id).unwrap_or(0.0) + score + 1.0
          }
        }
      }
      result
    }
    And(a, b_query) => {
      let left = self.evaluate(a, k1, b)
      let right = self.evaluate(b_query, k1, b)
      left.retain(fn(id, _) { right.contains(id) })
      left.each(fn(id, score) { left[id] = score + right[id] })
      left
    }
    Or(a, b_query) => {
      let left = self.evaluate(a, k1, b)
      let right = self.evaluate(b_query, k1, b)
      for id, score in right {
        left[id] = left.get(id).unwrap_or(0.0) + score
      }
      left
    }
    Not(q) => {
      let excluded = self.evaluate(q, k1, b)
      let result : Map[String, Double] = {}
      for id, _ in self.documents {
        if !excluded.contains(id) {
          result[id] = 0.0
        }
      }
      result
    }
  }
}

///|
pub fn run(request : Value) -> Value raise {
  let snapshot = get(request, "snapshot")
  let fields = if snapshot != Null {
    string_list(get(snapshot, "fields"))
  } else if get(request, "fields") != Null {
    string_list(get(request, "fields"))
  } else {
    ["text"]
  }
  if snapshot != Null &&
    (
      get(snapshot, "version") != Number(1.0) ||
      get(snapshot, "analyzer") != String("latin-words-cjk-unigrams-v1")
    ) {
    raise InputError("incompatible index snapshot")
  }
  let documents = if snapshot != Null {
    arr(get(snapshot, "documents")).copy()
  } else {
    arr(get(request, "documents")).copy()
  }
  if get(request, "actions") != Null {
    for action in arr(get(request, "actions")) {
      let id = str(get(action, "id"))
      let kind = str(get(action, "type"))
      if kind != "delete" && kind != "upsert" {
        raise InputError("unknown index action")
      }
      documents.retain(fn(doc) { get(doc, "id") != String(id) })
      if kind == "upsert" {
        let document = get(action, "document")
        if get(document, "id") != String(id) {
          raise InputError("action/document ID mismatch")
        }
        documents.push(document)
      }
    }
  }
  let index = build_index(documents, fields)
  let queries = match get(request, "queries") {
    Null => []
    other => string_list(other)
  }
  let k1 = optional_num(get(request, "k1"), 1.2)
  let b = optional_num(get(request, "b"), 0.75)
  if k1 <= 0.0 || b < 0.0 || b > 1.0 {
    raise InputError("invalid BM25 parameters")
  }
  let limit = optional_num(get(request, "limit"), 10.0).to_int()
  if limit < 0 || limit > 1000 {
    raise InputError("limit out of range")
  }
  let results = queries.map(fn(source) {
    let parsed = parse_query(source)
    let scores = index.evaluate(parsed, k1, b)
    let ids = scores.keys().collect()
    ids.sort_by(fn(a, b) {
      let c = scores[b].compare(scores[a])
      if c == 0 {
        a.compare(b)
      } else {
        c
      }
    })
    let hits : Array[Value] = []
    for i = 0; i < ids.length().min(limit); i = i + 1 {
      let id = ids[i]
      hits.push(
        record([
          ("id", String(id)),
          ("score", Number(scores[id])),
          ("document", index.documents[id]),
          ("highlights", highlights(index.documents[id], fields, parsed)),
        ]),
      )
    }
    record([
      ("query", String(source)),
      ("total", Number(ids.length().to_double())),
      ("hits", Array(hits)),
    ])
  })
  record([
    ("results", Array(results)),
    ("snapshot", index.snapshot()),
    ("terms", Number(index.postings.length().to_double())),
  ])
}
