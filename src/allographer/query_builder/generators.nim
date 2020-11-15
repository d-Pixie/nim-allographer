import json
from strformat import `&`
from strutils import contains, isUpperAscii

import base
from ../util import wrapUpper


# ==================== SELECT ====================

proc selectSql*(this: RDB): RDB =
  var queryString = ""

  if this.query.hasKey("distinct"):
    queryString.add("SELECT DISTINCT")
  else:
    queryString.add("SELECT")

  if this.query.hasKey("select"):
    for i, item in this.query["select"].getElems():
      if i > 0: queryString.add(",")
      var column = item.getStr()
      wrapUpper(column)
      queryString.add(&" {column}")
  else:
    queryString.add(" *")

  this.sqlString = queryString
  return this


proc fromSql*(this: RDB): RDB =
  var table = this.query["table"].getStr()
  wrapUpper(table)
  this.sqlString.add(&" FROM {table}")
  return this

proc selectFirstSql*(this:RDB): RDB =
  this.sqlString.add(" LIMIT 1")
  return this

proc selectByIdSql*(this:RDB, id:int, key:string): RDB =
  var key = key
  wrapUpper(key)
  if this.sqlString.contains("WHERE"):
    this.sqlString.add(&" AND {key} = ? LIMIT 1")
  else:
    this.sqlString.add(&" WHERE {key} = ? LIMIT 1")
  return this


proc joinSql*(this: RDB): RDB =
  if this.query.hasKey("join"):
    for row in this.query["join"]:
      var table = row["table"].getStr()
      wrapUpper(table)
      var column1 = row["column1"].getStr()
      wrapUpper(column1)
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()
      wrapUpper(column2)

      this.sqlString.add(&" INNER JOIN {table} ON {column1} {symbol} {column2}")

  return this


proc leftJoinSql*(this: RDB): RDB =
  if this.query.hasKey("left_join"):
    for row in this.query["left_join"]:
      var table = row["table"].getStr()
      wrapUpper(table)
      var column1 = row["column1"].getStr()
      wrapUpper(column1)
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()
      wrapUpper(column2)

      this.sqlString.add(&" LEFT JOIN {table} ON {column1} {symbol} {column2}")

  return this


proc whereSql*(this: RDB): RDB =
  if this.query.hasKey("where"):
    for i, row in this.query["where"].getElems():
      var column = row["column"].getStr()
      wrapUpper(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if i == 0:
        this.sqlString.add(&" WHERE {column} {symbol} {value}")
      else:
        this.sqlString.add(&" AND {column} {symbol} {value}")

  return this


proc orWhereSql*(this: RDB): RDB =
  if this.query.hasKey("or_where"):
    for row in this.query["or_where"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" OR {column} {symbol} {value}")
      else:
        this.sqlString.add(&" WHERE {column} {symbol} {value}")

  return this


proc whereBetweenSql*(this:RDB): RDB =
  if this.query.hasKey("where_between"):
    for row in this.query["where_between"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} BETWEEN {start} AND {stop}")
      else:
        this.sqlString.add(&" WHERE {column} BETWEEN {start} AND {stop}")

  return this


proc whereNotBetweenSql*(this:RDB): RDB =
  if this.query.hasKey("where_not_between"):
    for row in this.query["where_not_between"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} NOT BETWEEN {start} AND {stop}")
      else:
        this.sqlString.add(&" WHERE {column} NOT BETWEEN {start} AND {stop}")
  return this


proc whereInSql*(this:RDB): RDB =
  if this.query.hasKey("where_in"):
    var widthString = ""
    for row in this.query["where_in"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} IN ({widthString})")
      else:
        this.sqlString.add(&" WHERE {column} IN ({widthString})")
  return this


proc whereNotInSql*(this:RDB): RDB =
  if this.query.hasKey("where_not_in"):
    var widthString = ""
    for row in this.query["where_not_in"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} NOT IN ({widthString})")
      else:
        this.sqlString.add(&" WHERE {column} NOT IN ({widthString})")
  return this


proc whereNullSql*(this:RDB): RDB =
  if this.query.hasKey("where_null"):
    for row in this.query["where_null"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} is null")
      else:
        this.sqlString.add(&" WHERE {column} is null")
  return this


proc groupBySql*(this:RDB): RDB =
  if this.query.hasKey("group_by"):
    for row in this.query["group_by"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      if this.sqlString.contains("GROUP BY"):
        this.sqlString.add(&", {column}")
      else:
        this.sqlString.add(&" GROUP BY {column}")
  return this


proc havingSql*(this:RDB): RDB =
  if this.query.hasKey("having"):
    for i, row in this.query["having"].getElems():
      var column = row["column"].getStr()
      wrapUpper(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if i == 0:
        this.sqlString.add(&" HAVING {column} {symbol} {value}")
      else:
        this.sqlString.add(&" AND {column} {symbol} {value}")

  return this


proc orderBySql*(this:RDB): RDB =
  if this.query.hasKey("order_by"):
    for row in this.query["order_by"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var order = row["order"].getStr()

      if this.sqlString.contains("ORDER BY"):
        this.sqlString.add(&", {column} {order}")
      else:
        this.sqlString.add(&" ORDER BY {column} {order}")
  return this


proc limitSql*(this: RDB): RDB =
  if this.query.hasKey("limit"):
    var num = this.query["limit"].getInt()
    this.sqlString.add(&" LIMIT {num}")

  return this


proc offsetSql*(this: RDB): RDB =
  if this.query.hasKey("offset"):
    var num = this.query["offset"].getInt()
    this.sqlString.add(&" OFFSET {num}")

  return this


# ==================== INSERT ====================

proc insertSql*(this: RDB): RDB =
  var table = this.query["table"].getStr()
  wrapUpper(table)
  this.sqlString = &"INSERT INTO {table}"
  return this


proc insertValueSql*(this: RDB, items: JsonNode): RDB =
  var columns = ""
  var values = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0:
      columns.add(", ")
      values.add(", ")
    i += 1
    # If column name contains Upper letter, column name is covered by double quote
    var key = key
    wrapUpper(key)
    columns.add(key)

    if val.kind == JInt:
      this.placeHolder.add($(val.getInt()))
    elif val.kind == JFloat:
      this.placeHolder.add($(val.getFloat()))
    elif val.kind == JBool:
      this.placeHolder.add($(val.getBool()))
    elif val.kind == JObject:
      this.placeHolder.add($val)
    else:
      this.placeHolder.add(val.getStr())
    values.add("?")

  this.sqlString.add(&" ({columns}) VALUES ({values})")
  return this


proc insertValuesSql*(this: RDB, rows: openArray[JsonNode]): RDB =
  var columns = ""

  var i = 0
  for key, value in rows[0]:
    if i > 0: columns.add(", ")
    i += 1
    # If column name contains Upper letter, column name is covered by double quote
    var key = key
    wrapUpper(key)
    columns.add(key)

  var values = ""
  var valuesCount = 0
  for items in rows:
    var valueCount = 0
    var value = ""
    for key, val in items.pairs:
      if valueCount > 0: value.add(", ")
      valueCount += 1
      if val.kind == JInt:
        this.placeHolder.add($(val.getInt()))
      elif val.kind == JFloat:
        this.placeHolder.add($(val.getFloat()))
      elif val.kind == JBool:
        this.placeHolder.add($(val.getBool()))
      elif val.kind == JObject:
        this.placeHolder.add($val)
      else:
        this.placeHolder.add(val.getStr())
      value.add("?")

    if valuesCount > 0: values.add(", ")
    valuesCount += 1
    values.add(&"({value})")

  this.sqlString.add(&" ({columns}) VALUES {values}")
  return this


# ==================== UPDATE ====================

proc updateSql*(this: RDB): RDB =
  this.sqlString.add("UPDATE")

  var table = this.query["table"].getStr()
  wrapUpper(table)
  this.sqlString.add(&" {table} SET ")
  return this


proc updateValuesSql*(this: RDB, items:JsonNode): RDB =
  var value = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0: value.add(", ")
    i += 1
    var key = key
    wrapUpper(key)
    value.add(&"{key} = ?")

  this.sqlString.add(value)
  return this


# ==================== DELETE ====================

proc deleteSql*(this: RDB): RDB =
  this.sqlString.add("DELETE")
  return this


proc deleteByIdSql*(this: RDB, id: int, key: string): RDB =
  var key = key
  wrapUpper(key)
  this.sqlString.add(&" WHERE {key} = ?")
  return this

# ==================== Aggregates ====================

proc selectCountSql*(this: RDB): RDB =
  this.sqlString = "SELECT count(*) as aggregate"
  return this


proc selectMaxSql*(this:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  this.sqlString = &"SELECT max({column}) as aggregate"
  return this


proc selectMinSql*(this:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  this.sqlString = &"SELECT min({column}) as aggregate"
  return this


proc selectAvgSql*(this:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  this.sqlString = &"SELECT avg({column}) as aggregate"
  return this


proc selectSumSql*(this:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  this.sqlString = &"SELECT sum({column}) as aggregate"
  return this
