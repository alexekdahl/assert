import macros, strutils

const moduleName = "assert/contracts"


proc contractViolation(msg: string) {.noreturn.} =
  stderr.writeLine("CONTRACT VIOLATION:\n\t" & msg)

  when compileOption("stacktrace"):
    let trace = getStackTrace()
    for line in trace.splitLines():
      if not line.contains(moduleName) and line.len > 0:
        stderr.writeLine(line)

  quit(QuitFailure)


proc extractContracts(docComment: string): tuple[requires, ensures,
    invariants: seq[string]] =
  result.requires = @[]
  result.ensures = @[]

  let lines = docComment.splitLines()
  var currentSection = ""

  for line in lines:
    let trimmedLine = line.strip()
    if trimmedLine.startsWith("Requires:"):
      currentSection = "requires"
      continue
    elif trimmedLine.startsWith("Ensures:"):
      currentSection = "ensures"
      continue

    if currentSection == "requires" and trimmedLine.len > 0:
      result.requires.add(trimmedLine)
    elif currentSection == "ensures" and trimmedLine.len > 0:
      result.ensures.add(trimmedLine)


macro contract*(procDef: untyped): untyped =
  ## Applies Design by Contract principles to a procedure based on its documentation.
  result = procDef
  # For production builds, don't add contract checks
  if defined(noContracts):
    return

  var docComment = ""
  if procDef.kind == nnkProcDef:

    # Extract doc comment if it exists
    if procDef[6].kind == nnkStmtList and procDef[6].len > 0:
      if procDef[6][0].kind == nnkCommentStmt:
        docComment = procDef[6][0].strVal

  if docComment == "":
    return # No documentation, so no contracts to apply
  
  # Extract contracts from the documentation
  let contracts = extractContracts(docComment)

  # Create the contract checking code
  var preconditions = newStmtList()
  for req in contracts.requires:
    let condExpr = parseExpr(req)
    preconditions.add(quote do:
      if not(`condExpr`):
        let info = instantiationInfo()
        contractViolation(info.filename & ":" & $info.line &
          "\n\t\tPrecondition failed: " & `req`)
    )

  var postconditions = newStmtList()
  for ens in contracts.ensures:
    let condExpr = parseExpr(ens)
    postconditions.add(quote do:
      if not(`condExpr`):
        let info = instantiationInfo()
        contractViolation(info.filename & ":" & $info.line &
          "\n\t\tPostcondition failed: " & `ens`)
    )

  # Insert the contract checking code into the procedure
  let procBody = procDef[6]
  var newBody = newStmtList()

  # Copy the comment if it exists
  if procBody.len > 0 and procBody[0].kind == nnkCommentStmt:
    newBody.add(procBody[0])

  # Add precondition checks
  for precheck in preconditions:
    newBody.add(precheck)

  # Copy the original body except the first statement if it's a comment
  for i in 0..<procBody.len:
    if i > 0 or procBody[0].kind != nnkCommentStmt:
      newBody.add(procBody[i])

  # Add postcondition checks
  for postcheck in postconditions:
    newBody.add(postcheck)

  # Replace the procedure body with the new one
  procDef[6] = newBody
