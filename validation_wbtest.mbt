///|
test "qualified query highlights do not mark other fields" {
  let doc = record([("id", String("a")), ("fields", record([("title", String("moon")), ("body", String("moon moon"))]))])
  let result = highlights(doc, ["title", "body"], parse_query("title:moon"))
  assert_eq(arr(get(result, "title")).length(), 1)
  assert_eq(arr(get(result, "body")).length(), 0)
}

///|
test "fractional result limits and excessive query trees are rejected" {
  let failed = try { ignore(run(record([("documents", Array([])), ("limit", Number(1.5))]))); false } catch { _ => true }
  assert_true(failed)
  let words : Array[String] = []
  for i = 0; i < 257; i = i + 1 { words.push("moon") }
  let too_many = try { ignore(parse_query(words.join(" "))); false } catch { _ => true }
  assert_true(too_many)
}

///|
test "updates cannot conceal duplicate source identifiers" {
  let document = record([("id", String("same")), ("fields", record([("text", String("moon"))]))])
  let failed = try {
    ignore(run(record([("documents", Array([document, document])), ("actions", Array([record([("type", String("delete")), ("id", String("same"))])]))])))
    false
  } catch { _ => true }
  assert_true(failed)
}
