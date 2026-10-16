# Request and result guide

Every example below is an executable fixture. Assertions cover the listed result fields; additional output fields are documented by the API and other fixtures. Error cases intentionally reject the request.

## boolean search

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "MoonBit native compiler 中文"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "native MoonBit examples"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "unrelated"
      }
    }
  ],
  "queries": [
    "MoonBit AND native",
    "MoonBit NOT examples",
    "NOT MoonBit"
  ]
}
```

Expected result fields:

```json
{
  "results/0/total": 2,
  "results/1/hits/0/id": "a",
  "results/2/hits/0/id": "c"
}
```

## phrase positions

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "MoonBit native compiler 中文"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "native MoonBit examples"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "unrelated"
      }
    }
  ],
  "queries": [
    "\"native compiler\"",
    "\"MoonBit compiler\"",
    "中文"
  ]
}
```

Expected result fields:

```json
{
  "results/0/hits/0/id": "a",
  "results/1/total": 0,
  "results/2/hits/0/id": "a"
}
```

## delete update

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "MoonBit native compiler 中文"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "native MoonBit examples"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "unrelated"
      }
    }
  ],
  "actions": [
    {
      "type": "delete",
      "id": "a"
    },
    {
      "type": "upsert",
      "id": "b",
      "document": {
        "id": "b",
        "fields": {
          "text": "updated"
        }
      }
    }
  ],
  "queries": [
    "MoonBit",
    "updated"
  ]
}
```

Expected result fields:

```json
{
  "results/0/total": 0,
  "results/1/hits/0/id": "b"
}
```

## invalid syntax

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "MoonBit native compiler 中文"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "native MoonBit examples"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "unrelated"
      }
    }
  ],
  "queries": [
    "(MoonBit AND"
  ]
}
```

Expected: nonzero exit with an input error.

## duplicate identifiers

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "MoonBit native compiler 中文"
      }
    },
    {
      "id": "a",
      "fields": {
        "text": "MoonBit native compiler 中文"
      }
    }
  ]
}
```

Expected: nonzero exit with an input error.

## snapshot version

```json
{
  "snapshot": {
    "version": 2,
    "fields": [
      "text"
    ],
    "documents": [
      {
        "id": "a",
        "fields": {
          "text": "MoonBit native compiler 中文"
        }
      },
      {
        "id": "b",
        "fields": {
          "text": "native MoonBit examples"
        }
      },
      {
        "id": "c",
        "fields": {
          "text": "unrelated"
        }
      }
    ]
  }
}
```

Expected: nonzero exit with an input error.


# 0.2.0 additional executable scenarios

## filtered pagination with full result facets

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "y",
        "kind": "reference"
      }
    },
    {
      "id": "d",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": null
      }
    },
    {
      "id": "e",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x"
      }
    }
  ],
  "queries": [
    "moon"
  ],
  "where": {
    "tenant": "x"
  },
  "facets": [
    "kind"
  ],
  "offset": 1,
  "limit": 1
}
```

Expected result fields:

```json
{
  "results/0/total": 4,
  "results/0/hits/0/id": "b",
  "results/0/offset": 1,
  "results/0/facets/kind/missing": 1,
  "results/0/facets/kind/buckets/0/value": "guide",
  "results/0/facets/kind/buckets/0/count": 2,
  "results/0/facets/kind/buckets/1/value": null,
  "results/0/facets/kind/buckets/1/count": 1
}
```

## null filter does not include missing

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "y",
        "kind": "reference"
      }
    },
    {
      "id": "d",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": null
      }
    },
    {
      "id": "e",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x"
      }
    }
  ],
  "queries": [
    "moon"
  ],
  "where": {
    "kind": null
  }
}
```

Expected result fields:

```json
{
  "results/0/total": 1,
  "results/0/hits/0/id": "d"
}
```

## out of range page retains totals

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "y",
        "kind": "reference"
      }
    },
    {
      "id": "d",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": null
      }
    },
    {
      "id": "e",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x"
      }
    }
  ],
  "queries": [
    "moon"
  ],
  "offset": 10,
  "limit": 2,
  "facets": [
    "tenant"
  ]
}
```

Expected result fields:

```json
{
  "results/0/total": 5,
  "results/0/hits": [],
  "results/0/facets/tenant/buckets/0/count": 4
}
```

## invalid offset

```json
{
  "documents": [],
  "offset": 0.5
}
```

Expected: an input error.

## invalid metadata shape

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "moon"
      },
      "metadata": [
        1
      ]
    }
  ]
}
```

Expected: an input error.

## duplicate facets

```json
{
  "documents": [
    {
      "id": "a",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "b",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": "guide"
      }
    },
    {
      "id": "c",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "y",
        "kind": "reference"
      }
    },
    {
      "id": "d",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x",
        "kind": null
      }
    },
    {
      "id": "e",
      "fields": {
        "text": "moon"
      },
      "metadata": {
        "tenant": "x"
      }
    }
  ],
  "facets": [
    "kind",
    "kind"
  ]
}
```

Expected: an input error.
