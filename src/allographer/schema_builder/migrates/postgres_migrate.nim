import strformat, strutils, json
import
  ../table,
  ../column
import ../generators/postgres_generators
from ../../utils import pgWrapUpper


proc generateColumnString*(column:Column, tableName=""):string =
  var columnString = ""
  case column.typ:
  # int ===================================================================
  of rdbIncrements:
    columnString.add(
      serialGenerator(column.name)
    )
  of rdbInteger:
    columnString.add(
      intGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbSmallInteger:
    columnString.add(
      smallIntGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbMediumInteger:
    columnString.add(
      mediumIntGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbBigInteger:
    columnString.add(
      bigIntGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  # float =================================================================
  of rdbDecimal:
    columnString.add(
      decimalGenerator(
        column.name,
        tableName,
        parseInt($column.info["maximum"]),
        parseInt($column.info["digit"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  of rdbDouble:
    columnString.add(
      doubleGenerator(
        column.name,
        tableName,
        parseInt($column.info["maximum"]),
        parseInt($column.info["digit"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  of rdbFloat:
    columnString.add(
      floatGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  # char ==================================================================
  of rdbChar:
    columnString.add(
      charGenerator(
        column.name,
        tableName,
        parseInt($column.info["maxLength"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString
      )
    )
  of rdbString:
    columnString.add(
      stringGenerator(
        column.name,
        tableName,
        parseInt($column.info["maxLength"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString
      )
    )
  of rdbText:
    columnString.add(
      textGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString
      )
    )
  of rdbMediumText:
    columnString.add(
      textGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString
      )
    )
  of rdbLongText:
    columnString.add(
      textGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString
      )
    )
  # date ==================================================================
  of rdbDate:
    columnString.add(
      dateGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbDatetime:
    columnString.add(
      datetimeGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTime:
    columnString.add(
      timeGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTimestamp:
    columnString.add(
      timestampGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTimestamps:
    columnString.add(
      timestampsGenerator()
    )
  of rdbSoftDelete:
    columnString.add(
      softDeleteGenetator()
    )
  # others ================================================================
  of rdbBinary:
    columnString.add(
      blobGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString
      )
    )
  of rdbBoolean:
    columnString.add(
      boolGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultBool
      )
    )
  of rdbEnumField:
    columnString.add(
      enumGenerator(
        column.name,
        tableName,
        column.info["options"].getElems,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString
      )
    )
  of rdbJson:
    columnString.add(
      jsonGenerator(
        column.name,
        tableName,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultJson
      )
    )
  of rdbForeign:
    columnString.add(
      foreignColumnGenerator(column.name, column.isDefault, column.defaultInt)
    )
  of rdbStrForeign:
    columnString.add(
      strForeignColumnGenerator(
        column.name,
        column.info["maxLength"].getInt,
        column.isDefault,
        column.defaultString
      )
    )
  return columnString

proc generateForeignString(table:string, column:Column):string =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    return foreignGenerator(
        table,
        column.name,
        column.info["table"].getStr(),
        column.info["column"].getStr(),
        column.foreignOnDelete
      )

proc generateAlterForeignString(table:string, column:Column):string =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    return alterAddForeignGenerator(
      table,
      column.name,
      column.info["table"].getStr(),
      column.info["column"].getStr(),
      column.foreignOnDelete
    )

proc migrate*(self:Table):string =
  var columnString = ""
  var foreignString = ""
  for i, column in self.columns:
    if i > 0: columnString.add(", ")
    columnString.add(
      generateColumnString(column, self.name)
    )
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if columnString.len > 0 or foreignString.len > 0: foreignString.add(", ")
      foreignString.add(
        generateForeignString(self.name, column)
      )

  var tableName = self.name
  pgWrapUpper(tableName)
  return &"CREATE TABLE {tableName} ({columnString}{foreignString})"

proc migrateAlter*(table:string, column:Column):seq[string] =
  let columnString = generateColumnString(column, table)
  let foreignString = generateAlterForeignString(table, column)

  result = @[
    &"ALTER TABLE \"{table}\" ADD COLUMN {columnString}"
  ]

  if foreignString.len > 0:
    result.add( &"ALTER TABLE \"{table}\" ADD {foreignString}" )

proc generateAlterDeleteQuery*(table:string, column:Column):string =
  return alterDeleteGenerator(table, column.name)

proc generateAlterDeleteForeignQueries*(table:string, column:Column):seq[string] =
  return @[
    alterDeleteForeignGenerator(
      table,
      column.name,
    ),
    alterDeleteGenerator(
      table,
      column.name
    )
  ]

proc createIndex*(table, column:string):string =
  return indexGenerate(table, column)
