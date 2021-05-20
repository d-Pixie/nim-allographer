import asyncdispatch, json, times, options
include db_postgres
import ../connection

type
  AsyncPool* = ref object
    conn*: DbConn
    isBusy*: bool
    createdAt*: int64
  AsyncConnections* = ref object
    pools*: seq[AsyncPool]
    timeout*:int

  ## Excpetion to catch on errors
  PGError* = object of Exception

# open(connection, user, password, database)

proc asyncOpen*(
    connection,
    user,
    password,
    database: string,
    maxConnections=1,
    timeout=30,
  ): AsyncConnections =
  ## Create a new async pool of num connections.
  var pools = newSeq[AsyncPool](maxConnections)
  for i in 0..<maxConnections:
    pools[i] = AsyncPool(
      conn: open(connection, user, password, database),
      isBusy: false,
      createdAt: getTime().toUnix()
    )
  return AsyncConnections(pools:pools, timeout:timeout)

proc getFreeConn(self:AsyncConnections):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.len:
      if not self.pools[i].isBusy:
        self.pools[i].isBusy = true
        echo "=== use " & $i
        return i
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.timeout:
      echo "timeout"
      break

proc returnConn(self: AsyncConnections, i: int) =
  echo "=== release " & $i
  self.pools[i].isBusy = false

proc getColumns(dbColumns:DbColumns):seq[array[3, string]] =
  var columns = newSeq[array[3, string]](dbColumns.len)
  for i, row in dbColumns:
    columns[i] = [row.name, $row.typ.kind, $row.typ.size]
  return columns

proc toJson(results:openArray[seq[string]], columns:openArray[array[3, string]]):seq[JsonNode] =
  var response_table = newSeq[JsonNode](results.len)
  for index, rows in results.pairs:
    var response_row = newJObject()
    for i, row in rows:
      let key = columns[i][0]
      let typ = columns[i][1]
      let size = columns[i][2]

      if row == "":
        response_row[key] = newJNull()
      elif [$dbInt, $dbUInt].contains(typ):
        response_row[key] = newJInt(row.parseInt)
      elif [$dbDecimal, $dbFloat].contains(typ):
        response_row[key] = newJFloat(row.parseFloat)
      elif [$dbBool].contains(typ):
        if row == "f":
          response_row[key] = newJBool(false)
        elif row == "t":
          response_row[key] = newJBool(true)
      elif [$dbJson].contains(typ):
        response_row[key] = row.parseJson
      else:
        response_row[key] = newJString(row)

    response_table[index] = response_row
  return response_table

proc checkError(db: DbConn) =
  ## Raises a DbError exception.
  var message = pqErrorMessage(db)
  if message.len > 0:
    raise newException(PGError, $message)


# ==================================================
proc asyncGetCore(db: DbConn, query: SqlQuery, args: seq[string]):Future[(seq[Row], DbColumns)] {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args))
  if success != 1: dbError(db) # never seen to fail when async
  var dbColumns: DbColumns
  var rows = newSeq[Row]()
  await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      await sleepAsync(1)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    setColumnInfo(dbColumns, pqresult, pqnfields(pqresult))
    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      rows.add(row)
    pqclear(pqresult)
  return (rows, dbColumns)

proc asyncGetAllRows(self:AsyncConnections, query: SqlQuery, args: seq[string]):Future[seq[JsonNode]] {.async.} =
  let connI = await getFreeConn(self)
  let (rows, dbColumns) = await asyncGetCore(self.pools[connI].conn, query, args)
  self.returnConn(connI)
  let columns = getColumns(dbColumns)
  return toJson(rows, columns)

proc asyncGetAllRow(self:AsyncConnections, query: SqlQuery, args: seq[string]):Future[Option[JsonNode]] {.async.} =
  let connI = await getFreeConn(self)
  let (rows, dbColumns) = await asyncGetCore(self.pools[connI].conn, query, args)
  self.returnConn(connI)
  if rows.len == 0:
    return none(JsonNode)
  let columns = getColumns(dbColumns)
  return toJson(@[rows[0]], columns)[0].some

when isMainModule:
  proc main(){.async.} =
    block:
      let conn = asyncOpen("postgres:5432", "user", "Password!", "allographer", 50, 30)
      let sql = "select pg_sleep(5)"
      var futures = newSeq[Future[seq[JsonNode]]](5)
      let start = cpuTime()
      for i in 0..<5:
        futures[i] = conn.asyncGetAllRows(sql(sql), @[])
      echo await all(futures)
      echo (cpuTime() - start) * 10
  waitFor main()

# proc asyncGetRow(db: DbConn, query: SqlQuery, args: seq[string]):Future[Option[JsonNode]] {.async.} =
#   assert db.status == CONNECTION_OK
#   let success = pqsendQuery(db, dbFormat(query, args))
#   if success != 1: dbError(db) # never seen to fail when async
#   var dbColumns: DbColumns
#   var rows = newSeq[Row]()
#   while true:
#     let success = pqconsumeInput(db)
#     if success != 1: dbError(db) # never seen to fail when async
#     if pqisBusy(db) == 1:
#       await sleepAsync(1)
#       continue
#     var pqresult = pqgetResult(db)
#     if pqresult == nil:
#       # Check if its a real error or just end of results
#       db.checkError()
#       break
#     setColumnInfo(dbColumns, pqresult, pqnfields(pqresult))
#     var cols = pqnfields(pqresult)
#     var row = newRow(cols)
#     for i in 0'i32..pqNtuples(pqresult)-1:
#       setRow(pqresult, row, i, cols)
#       rows.add(row)
#     pqclear(pqresult)

#   if rows.len == 0:
#     return none(JsonNode)

#   let columns = getColumns(dbColumns)
#   return toJson(rows, columns)[0].some

# proc asyncGetRow*(pool:AsyncPool,
#                     sqlString:string,
#                     args:seq[string]
#   ):Future[Option[JsonNode]] {.async.} =
#     let conIdx = await pool.getFreeConnIdx()
#     result = await asyncGetRow(pool.conns[conIdx], sql sqlString, args)
#     pool.returnConn(conIdx)

# proc asyncGetAllRowsPlain(db: DbConn, query: SqlQuery, args: seq[string]):Future[seq[Row]] {.async.} =
#   assert db.status == CONNECTION_OK
#   let success = pqsendQuery(db, dbFormat(query, args))
#   if success != 1: dbError(db) # never seen to fail when async
#   while true:
#     let success = pqconsumeInput(db)
#     if success != 1: dbError(db) # never seen to fail when async
#     if pqisBusy(db) == 1:
#       await sleepAsync(1)
#       continue
#     var pqresult = pqgetResult(db)
#     if pqresult == nil:
#       # Check if its a real error or just end of results
#       db.checkError()
#       break
#     var cols = pqnfields(pqresult)
#     var row = newRow(cols)
#     for i in 0'i32..pqNtuples(pqresult)-1:
#       setRow(pqresult, row, i, cols)
#       result.add row
#     pqclear(pqresult)

# proc asyncGetAllRowsPlain*(pool:AsyncPool,
#                           sqlString:string,
#                           args:seq[string]
#   ):Future[seq[Row]] {.async.} =
#     let conIdx = await pool.getFreeConnIdx()
#     result = await asyncGetAllRowsPlain(pool.conns[conIdx], sql sqlString, args)
#     pool.returnConn(conIdx)


# proc asyncGetRowPlain(db: DbConn, query: SqlQuery, args: seq[string]):Future[Row] {.async.} =
#   assert db.status == CONNECTION_OK
#   let success = pqsendQuery(db, dbFormat(query, args))
#   if success != 1: dbError(db) # never seen to fail when async
#   while true:
#     let success = pqconsumeInput(db)
#     if success != 1: dbError(db) # never seen to fail when async
#     if pqisBusy(db) == 1:
#       await sleepAsync(1)
#       continue
#     var pqresult = pqgetResult(db)
#     if pqresult == nil:
#       # Check if its a real error or just end of results
#       db.checkError()
#       break
#     var cols = pqnfields(pqresult)
#     var row = newRow(cols)
#     setRow(pqresult, row, 0, cols)
#     result.add(row)
#     pqclear(pqresult)


# proc asyncGetRowPlain*(pool:AsyncPool,
#                         sqlString:string,
#                         args:seq[string]
# ):Future[Row] {.async.} =
#   let conIdx = await pool.getFreeConnIdx()
#   result = await asyncGetRowPlain(pool.conns[conIdx], sql sqlString, args)
#   pool.returnConn(conIdx)


# proc asyncExec(db: DbConn, query: SqlQuery, args: seq[string]) {.async.} =
#   assert db.status == CONNECTION_OK
#   let success = pqsendQuery(db, dbFormat(query, args))
#   if success != 1: dbError(db)
#   while true:
#     let success = pqconsumeInput(db)
#     if success != 1: dbError(db) # never seen to fail when async
#     if pqisBusy(db) == 1:
#       await sleepAsync(1)
#       continue
#     var pqresult = pqgetResult(db)
#     if pqresult == nil:
#       # Check if its a real error or just end of results
#       db.checkError()
#       break
#     pqclear(pqresult)

# proc asyncExec*(pool:AsyncPool,
#                   sqlString:string,
#                   args:seq[string]
# ) {.async.} =
#   let conIdx = await pool.getFreeConnIdx()
#   await asyncExec(pool.conns[conIdx], sql sqlString, args)
#   pool.returnConn(conIdx)
