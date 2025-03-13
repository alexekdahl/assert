import assert
import math

proc divide(a, b: int): int {.contract.} =
  ## Integer division
  ## Requires:
  ##   b != 0
  ## Ensures:
  ##   result * b == a

  result = a div b

proc add5to5(x: int): int {.contract.} =
  ## Adds 5 to 5
  ## Requires:
  ##   x == 5

  result = x + 5

when isMainModule:
  echo "10 / 2 = ", divide(10, 2) # Works fine
  echo "adding 5 to 10 = ", add5to5(10) # This will panic if contracts are enabled
