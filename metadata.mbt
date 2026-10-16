///|
fn metadata_matches(document : Value, query : Map[String, Value]) -> Bool {
  let fields = match get(document, "metadata") { Object(fields) => fields; _ => Map([]) }
  for key, expected in query {
    if !fields.contains(key) || fields[key] != expected { return false }
  }
  true
}

///|
fn facet_fields(source : Value) -> Array[String] raise {
  let fields = if source == Null { [] } else { string_list(source) }
  let seen : Map[String, Bool] = Map([])
  for field in fields {
    if field == "" || seen.contains(field) { raise InputError("empty or duplicate facet field") }
    seen[field] = true
  }
  fields
}

///|
fn SearchIndex::facets(self : SearchIndex, ids : Array[String], fields : Array[String]) -> Value {
  let result : Map[String, Value] = Map([])
  for field in fields {
    let counts : Map[String, Int] = Map([]); let values : Map[String, Value] = Map([])
    let mut missing = 0
    for id in ids {
      let metadata = match get(self.documents[id], "metadata") { Object(fields) => fields; _ => Map([]) }
      match metadata.get(field) {
        None => missing += 1
        Some(value) => {
          let key = canonical(value); values[key] = value
          counts[key] = counts.get(key).unwrap_or(0) + 1
        }
      }
    }
    let keys = counts.keys().collect()
    keys.sort_by(fn(a, b) { let order = counts[b].compare(counts[a]); if order == 0 { a.lexical_compare(b) } else { order } })
    result[field] = record([
      ("missing", Number(missing.to_double())),
      ("buckets", Array(keys.map(fn(key) { record([("value", values[key]), ("count", Number(counts[key].to_double()))]) }))),
    ])
  }
  Object(result)
}
