///|
test "filtered pagination with full result facets" {
  let result = run(
    parse_value(
      "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"b\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"c\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"y\",\"kind\":\"reference\"}},{\"id\":\"d\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":null}},{\"id\":\"e\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\"}}],\"queries\":[\"moon\"],\"where\":{\"tenant\":\"x\"},\"facets\":[\"kind\"],\"offset\":1,\"limit\":1}",
    ),
  )
  assert_eq(test_at(result, ["results", "0", "total"]), parse_value("4"))
  assert_eq(
    test_at(result, ["results", "0", "hits", "0", "id"]),
    parse_value("\"b\""),
  )
  assert_eq(test_at(result, ["results", "0", "offset"]), parse_value("1"))
  assert_eq(
    test_at(result, ["results", "0", "facets", "kind", "missing"]),
    parse_value("1"),
  )
  assert_eq(
    test_at(result, ["results", "0", "facets", "kind", "buckets", "0", "value"]),
    parse_value("\"guide\""),
  )
  assert_eq(
    test_at(result, ["results", "0", "facets", "kind", "buckets", "0", "count"]),
    parse_value("2"),
  )
  assert_eq(
    test_at(result, ["results", "0", "facets", "kind", "buckets", "1", "value"]),
    parse_value("null"),
  )
  assert_eq(
    test_at(result, ["results", "0", "facets", "kind", "buckets", "1", "count"]),
    parse_value("1"),
  )
}

///|
test "null filter does not include missing" {
  let result = run(
    parse_value(
      "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"b\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"c\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"y\",\"kind\":\"reference\"}},{\"id\":\"d\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":null}},{\"id\":\"e\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\"}}],\"queries\":[\"moon\"],\"where\":{\"kind\":null}}",
    ),
  )
  assert_eq(test_at(result, ["results", "0", "total"]), parse_value("1"))
  assert_eq(
    test_at(result, ["results", "0", "hits", "0", "id"]),
    parse_value("\"d\""),
  )
}

///|
test "out of range page retains totals" {
  let result = run(
    parse_value(
      "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"b\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"c\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"y\",\"kind\":\"reference\"}},{\"id\":\"d\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":null}},{\"id\":\"e\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\"}}],\"queries\":[\"moon\"],\"offset\":10,\"limit\":2,\"facets\":[\"tenant\"]}",
    ),
  )
  assert_eq(test_at(result, ["results", "0", "total"]), parse_value("5"))
  assert_eq(test_at(result, ["results", "0", "hits"]), parse_value("[]"))
  assert_eq(
    test_at(result, [
      "results", "0", "facets", "tenant", "buckets", "0", "count",
    ]),
    parse_value("4"),
  )
}

///|
test "invalid offset" {
  let failed = try {
    ignore(run(parse_value("{\"documents\":[],\"offset\":0.5}")))
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}

///|
test "invalid metadata shape" {
  let failed = try {
    ignore(
      run(
        parse_value(
          "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"},\"metadata\":[1]}]}",
        ),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}

///|
test "duplicate facets" {
  let failed = try {
    ignore(
      run(
        parse_value(
          "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"b\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":\"guide\"}},{\"id\":\"c\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"y\",\"kind\":\"reference\"}},{\"id\":\"d\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\",\"kind\":null}},{\"id\":\"e\",\"fields\":{\"text\":\"moon\"},\"metadata\":{\"tenant\":\"x\"}}],\"facets\":[\"kind\",\"kind\"]}",
        ),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}
