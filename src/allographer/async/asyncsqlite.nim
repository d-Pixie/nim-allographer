import db_sqlite
import ../connection


type
  ## db pool
  AsyncPool* = ref object
    conns*: seq[DbConn]
    busy*: array[MAX_CONNECTION, bool]

  ## Excpetion to catch on errors
  PGError* = object of Exception


proc newAsyncPool*(
    connection,
    user,
    password,
    database: string,
    num: int
  ): AsyncPool =
  ## Create a new async pool of num connections.
  result = AsyncPool()
  for i in 0..<num:
    let conn = open(connection, user, password, database)
    assert conn.status == CONNECTION_OK
    result.conns.add conn

proc getFreeConnIdx*(pool: AsyncPool): Future[int] {.async.} =
  ## Wait for a free connection and return it.
  while true:
    for conIdx in 0..<pool.conns.len:
      if not pool.busy[conIdx]:
        pool.busy[conIdx] = true
        return conIdx
    await sleepAsync(10)

proc returnConn*(pool: AsyncPool, conIdx: int) =
  ## Make the connection as free after using it and getting results.
  pool.busy[conIdx] = false

proc asyncGetAllRows(db: DbConn, query: SqlQuery, args: seq[string]):Future[seq[JsonNode]] {.async.} =
  discard
