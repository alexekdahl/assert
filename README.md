# Design by Contract for Nim

A lightweight Design by Contract implementation for Nim allowing you to enforce preconditions and postconditions

## Installation

```
nimble install assert
```

## Usage

```nim
import assert
import math

proc divide(a, b: int): int {.contract.} =
  ## Integer division of a by b.
  ## Requires:
  ##   b != 0
  ## Ensures:
  ##   result * b == a
  result = a div b
```

## Compile Options

- **Regular Build**: Contracts fully enabled
  ```
  nim c program.nim
  ```

- **Production Build**: No contract checks (zero overhead)
  ```
  nim c -d:noContracts program.nim
  ```

## Note

When a contract is violated, the program terminates with an error message
