allographer
===

A query builder library inspired by [Laravel/PHP](https://readouble.com/laravel/6.0/en/queries.html) and [Orator/Python](https://orator-orm.com) for Nim

## Easy to access RDB
### Query Builder
```
import allographer/QueryBuilder

var result = RDB()
            .table("users")
            .select("id", "email", "name")
            .limit(5)
            .offset(10)
            .get()
echo result

>> SELECT id, email, name FROM users LIMIT 5 OFFSET 10
>> @[
  {"id":"11","email":"user11@gmail.com","name":"user11"},
  {"id":"12","email":"user12@gmail.com","name":"user12"},
  {"id":"13","email":"user13@gmail.com","name":"user13"},
  {"id":"14","email":"user14@gmail.com","name":"user14"},
  {"id":"15","email":"user15@gmail.com","name":"user15"}
]
```

### Schema Builder
```
import allographer/SchemaBuilder

Schema().create([
  Model().create("auth", [
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().timestamp("created_at").default()
  ])
])

>> CREATE TABLE auth (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR,
    created_at DATETIME DEFAULT (NOW())
)

Schema().create([
  Table().create("users", [
    Column().increments("id"),
    Column().string("name"),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
])

>> CREATE TABLE users (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR NOT NULL,
    auth_id INT,
    FOREIGN KEY(auth_id) REFERENCES auth(id) ON DELETE SET NULL
) 
```

---

## Install
```
nimble install https://github.com/itsumura-h/nim-allographer
```

## Set up
First of all, add nim binary path
```
export PATH=$PATH:~/.nimble/bin
```
After install allographer, "dbtool" command is going to be available.  

### Create config file
```
cd /your/project/dir
dbtool makeConf
```
`/your/project/dir/config/database.ini` will be generated

### Edit confing file
By default, config file is set to use sqlite

```
[Connection]
driver: "sqlite"
conn: "/your/project/dir/db.sqlite3"
user: ""
password: ""
database: ""

[Log]
display: "true"
file: "true"
```

- driver: `sqlite` or `mysql` or `postgres`
- conn: `sqlite/file/path` or `host:port`
- user: login user name
- password: login password
- database: specify the database

From "conn" to "database", these are correspond to args of open proc of Nim std db package
```
let db = open(conn, user, password, database)
```

If you set "true" in "display" of "Log", SQL query will be display in terminal, otherwise nothing will be display.

### Load config file
```
dbtool loadConf
```
settings will be applied

## Examples
[Query Builder](./documents/QueryBuilder.md)  
[Schema Builder](./documents/SchemaBuilder.md)  


## Todo
- [x] Database migration
- [ ] Mapping with column and data then return JsonNode
- [ ] Aggregate methods (count, max, min, avg, and sum)
