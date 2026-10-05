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
