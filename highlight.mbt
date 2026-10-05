///|
fn collect_positive(query : Query, terms : Map[String, Bool]) -> Unit {
  match query {
    Term(_, term) => terms[term] = true
    Phrase(_, words) =>
      for word in words {
        terms[word] = true
      }
    And(a, b) | Or(a, b) => {
      collect_positive(a, terms)
      collect_positive(b, terms)
    }
    Not(_) => ()
  }
}

///|
fn highlights(
  document : Value,
  fields : Array[String],
  query : Query,
) -> Value raise {
  let terms : Map[String, Bool] = Map([])
  collect_positive(query, terms)
  let result : Map[String, Value] = Map([])
  for field in fields {
    let tokens = analyze(optional_str(get(get(document, "fields"), field), ""))
    result[field] = Array(
      tokens
      .filter(fn(token) { terms.contains(token.term) })
      .map(fn(token) {
        record([
          ("term", String(token.term)),
          ("start", Number(token.start.to_double())),
          ("end", Number(token.end.to_double())),
        ])
      }),
    )
  }
  Object(result)
}
