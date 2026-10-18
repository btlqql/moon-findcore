///|
pub fn compare_search(request : Value) -> Value raise {
  let old=get(request,"old"); let next=get(request,"new"); ignore(obj(old)); ignore(obj(next))
  for key in ["queries","limit","offset","where","facets","k1","b"] { if get(old,key)!=get(next,key) { raise InputError("search comparison requires identical query/filter/ranking/page settings") } }
  let a=arr(get(search_request(old),"results")); let b=arr(get(search_request(next),"results"))
  let output : Array[Value] = []; let mut changed=0
  for i=0; i<a.length(); i=i+1 {
    let left=arr(get(a[i],"hits")); let right=arr(get(b[i],"hits"))
    let old_ids=left.map(fn(hit){str(get(hit,"id"))}); let new_ids=right.map(fn(hit){str(get(hit,"id"))})
    let added=new_ids.filter(fn(id){!old_ids.contains(id)}); let removed=old_ids.filter(fn(id){!new_ids.contains(id)})
    let score_changes : Array[Value] = []
    for before in left { for after in right { if get(before,"id")==get(after,"id") && get(before,"score")!=get(after,"score") { score_changes.push(record([("id",get(before,"id")),("before",get(before,"score")),("after",get(after,"score"))])) } } }
    let drift=old_ids!=new_ids || get(a[i],"total")!=get(b[i],"total") || !score_changes.is_empty() || get(a[i],"facets")!=get(b[i],"facets")
    if drift { changed+=1 }
    output.push(record([("query",get(a[i],"query")),("before_total",get(a[i],"total")),("after_total",get(b[i],"total")),("added",strings(added)),("removed",strings(removed)),("before_order",strings(old_ids)),("after_order",strings(new_ids)),("score_changes",Array(score_changes)),("changed",Bool(drift))]))
  }
  record([("queries",Array(output)),("changed_count",Number(changed.to_double())),("equal_on_queries",Bool(changed==0)),("scope",String("returned pages and totals at fixed query settings; not a complete index equivalence proof"))])
}

///|
pub fn run(request : Value) -> Value raise {
  match optional_str(get(request,"operation"),"search") { "search" => search_request(request); "compare" => compare_search(request); _ => raise InputError("operation must be search or compare") }
}
