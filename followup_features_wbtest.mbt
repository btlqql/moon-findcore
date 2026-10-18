///|
fn followup_at(value : Value, keys : Array[String]) -> Value raise {
  let mut current = value
  for key in keys {
    current = match current {
      Object(fields) => fields[key]
      Array(items) => {
        let index = match @json.parse(key) {
          Json::Number(n, ..) => n.to_int()
          _ => raise InputError("invalid test index")
        }
        items[index]
      }
      _ => raise InputError("invalid test path")
    }
  }
  current
}

///|
test "followup search update replay" {
  let result = run(
    from_json(
      @json.parse(
        "{\"operation\":\"compare\",\"old\":{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"}},{\"id\":\"b\",\"fields\":{\"text\":\"sun\"}}],\"queries\":[\"moon\"]},\"new\":{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"}},{\"id\":\"b\",\"fields\":{\"text\":\"sun\"}}],\"queries\":[\"moon\"],\"actions\":[{\"id\":\"a\",\"type\":\"delete\"},{\"id\":\"b\",\"type\":\"upsert\",\"document\":{\"id\":\"b\",\"fields\":{\"text\":\"moon\"}}}]}}",
      ),
    ),
  )
  assert_eq(followup_at(result, ["changed_count"]), from_json(@json.parse("1")))
  assert_eq(
    followup_at(result, ["queries", "0", "added"]),
    from_json(@json.parse("[\"b\"]")),
  )
  assert_eq(
    followup_at(result, ["queries", "0", "removed"]),
    from_json(@json.parse("[\"a\"]")),
  )
}

///|
test "followup search identical replay" {
  let result = run(
    from_json(
      @json.parse(
        "{\"operation\":\"compare\",\"old\":{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"}},{\"id\":\"b\",\"fields\":{\"text\":\"sun\"}}],\"queries\":[\"moon\"]},\"new\":{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"}},{\"id\":\"b\",\"fields\":{\"text\":\"sun\"}}],\"queries\":[\"moon\"]}}",
      ),
    ),
  )
  assert_eq(followup_at(result, ["changed_count"]), from_json(@json.parse("0")))
  assert_eq(
    followup_at(result, ["equal_on_queries"]),
    from_json(@json.parse("true")),
  )
}

///|
test "followup query window mismatch" {
  let bad = try {
    ignore(
      run(
        from_json(
          @json.parse(
            "{\"operation\":\"compare\",\"old\":{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"}},{\"id\":\"b\",\"fields\":{\"text\":\"sun\"}}],\"queries\":[\"moon\"]},\"new\":{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"}},{\"id\":\"b\",\"fields\":{\"text\":\"sun\"}}],\"queries\":[\"moon\"],\"limit\":1}}",
          ),
        ),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
