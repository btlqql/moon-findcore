///|
fn test_at(value : Value, parts : Array[String]) -> Value raise {
  let mut current = value
  for part in parts {
    current = match current {
      Object(fields) =>
        match fields.get(part) {
          Some(v) => v
          None => raise InputError("test key missing: " + part)
        }
      Array(items) => items[num(parse_value(part)).to_int()]
      _ => raise InputError("invalid test traversal")
    }
  }
  current
}

///|
test "boolean search" {
  let result = run(
    parse_value(
      "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"MoonBit native compiler 中文\"}},{\"id\":\"b\",\"fields\":{\"text\":\"native MoonBit examples\"}},{\"id\":\"c\",\"fields\":{\"text\":\"unrelated\"}}],\"queries\":[\"MoonBit AND native\",\"MoonBit NOT examples\",\"NOT MoonBit\"]}",
    ),
  )
  assert_eq(test_at(result, ["results", "0", "total"]), parse_value("2"))
  assert_eq(
    test_at(result, ["results", "1", "hits", "0", "id"]),
    parse_value("\"a\""),
  )
  assert_eq(
    test_at(result, ["results", "2", "hits", "0", "id"]),
    parse_value("\"c\""),
  )
}

///|
test "phrase positions" {
  let result = run(
    parse_value(
      "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"MoonBit native compiler 中文\"}},{\"id\":\"b\",\"fields\":{\"text\":\"native MoonBit examples\"}},{\"id\":\"c\",\"fields\":{\"text\":\"unrelated\"}}],\"queries\":[\"\\\"native compiler\\\"\",\"\\\"MoonBit compiler\\\"\",\"中文\"]}",
    ),
  )
  assert_eq(
    test_at(result, ["results", "0", "hits", "0", "id"]),
    parse_value("\"a\""),
  )
  assert_eq(test_at(result, ["results", "1", "total"]), parse_value("0"))
  assert_eq(
    test_at(result, ["results", "2", "hits", "0", "id"]),
    parse_value("\"a\""),
  )
}

///|
test "delete update" {
  let result = run(
    parse_value(
      "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"MoonBit native compiler 中文\"}},{\"id\":\"b\",\"fields\":{\"text\":\"native MoonBit examples\"}},{\"id\":\"c\",\"fields\":{\"text\":\"unrelated\"}}],\"actions\":[{\"type\":\"delete\",\"id\":\"a\"},{\"type\":\"upsert\",\"id\":\"b\",\"document\":{\"id\":\"b\",\"fields\":{\"text\":\"updated\"}}}],\"queries\":[\"MoonBit\",\"updated\"]}",
    ),
  )
  assert_eq(test_at(result, ["results", "0", "total"]), parse_value("0"))
  assert_eq(
    test_at(result, ["results", "1", "hits", "0", "id"]),
    parse_value("\"b\""),
  )
}

///|
test "invalid syntax" {
  let failed = try {
    ignore(
      run(
        parse_value(
          "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"MoonBit native compiler 中文\"}},{\"id\":\"b\",\"fields\":{\"text\":\"native MoonBit examples\"}},{\"id\":\"c\",\"fields\":{\"text\":\"unrelated\"}}],\"queries\":[\"(MoonBit AND\"]}",
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
test "duplicate identifiers" {
  let failed = try {
    ignore(
      run(
        parse_value(
          "{\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"MoonBit native compiler 中文\"}},{\"id\":\"a\",\"fields\":{\"text\":\"MoonBit native compiler 中文\"}}]}",
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
test "snapshot version" {
  let failed = try {
    ignore(
      run(
        parse_value(
          "{\"snapshot\":{\"version\":2,\"fields\":[\"text\"],\"documents\":[{\"id\":\"a\",\"fields\":{\"text\":\"MoonBit native compiler 中文\"}},{\"id\":\"b\",\"fields\":{\"text\":\"native MoonBit examples\"}},{\"id\":\"c\",\"fields\":{\"text\":\"unrelated\"}}]}}",
        ),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}
