Example: Query Builder
===
[back](../README.md)

### SELECT
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
    @["11", "user11@gmail.com", "user11"],
    @["12", "user12@gmail.com", "user12"],
    @["13", "user13@gmail.com", "user13"],
    @["14", "user14@gmail.com", "user14"],
    @["15", "user15@gmail.com", "user15"]
]
```
```
import allographer/QueryBuilder

let resultRow = RDB()
                .table("users")
                .select()
                .where("id", "=", 3)
                .get()
echo resultRow

>> SELECT * FROM users WHERE id = 3
>> @[
  @["3", "user3", "user3@gmail.com", "246 Ferguson Village Apt. 582\nNew Joshua, IL 24200", "$2a$10$gmKpgtO535lkw0eAcGiRyefdEg6TXr9S.z6vhsn4X.mBYtP0Thfny", "$2a$10$gmKpgtO535lkw0eAcGiRye", "2012-11-24", "2", "2019-09-26 19:11:28.159367", "2019-09-26 19:11:28.159369"]
]
```
```
import allographer/QueryBuilder

let resultRow = RDB().table("users").select("id", "name", "email").where("id", ">", 5).first()
echo resultRow

>> SELECT id, name, email FROM users WHERE id > 5
>> @["6", "user6", "user6@gmail.com"]
```
```
import allographer/QueryBuilder

let resultRow = RDB().table("users").find(3)
echo resultRow

>> SELECT * FROM users WHERE id = 3
>> @["3", "user3", "user3@gmail.com", "246 Ferguson Village Apt. 582\nNew Joshua, IL 24200", "$2a$10$gmKpgtO535lkw0eAcGiRyefdEg6TXr9S.z6vhsn4X.mBYtP0Thfny", "$2a$10$gmKpgtO535lkw0eAcGiRye", "2012-11-24", "2", "2019-09-26 19:11:28.159367", "2019-09-26 19:11:28.159369"]
```
```
import allographer/QueryBuilder

let result = RDB()
            .table("users")
            .select("id", "email", "name")
            .where("id", ">", 4)
            .where("id", "<=", 10)
            .get()
echo result

>> SELECT id, email, name FROM users WHERE id > 4 AND id <= 10
>> @[
    @["5", "user5@gmail.com", "user5"],
    @["6", "user6@gmail.com", "user6"],
    @["7", "user7@gmail.com", "user7"],
    @["8", "user8@gmail.com", "user8"],
    @["9", "user9@gmail.com", "user9"],
    @["10", "user10@gmail.com", "user10"]
]
```
```
import allographer/QueryBuilder

let result = RDB()
            .table("users")
            .select("users.name", "users.auth_id")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("users.auth_id", "=", 1)
            .where("users.id", "<", 5)
            .get()
echo result

>> SELECT users.name, users.auth_id FROM users JOIN auth ON auth.id = users.auth_id WHERE users.auth_id = 1 AND users.id < 5
>> @[
  @["user1", "1"],
  @["user2", "1"],
  @["user4", "1"]
]
```

### INSERT
```
import allographer/QueryBuilder

RDB()
.table("users")
.insert(%*{
  "name": "John",
  "email": "John@gmail.com"
})
.exec()

>> INSERT INTO users (name, email) VALUES ("John", "John@gmail.com")
```
```
import allographer/QueryBuilder

echo RDB()
.table("users")
.insert(%*{
  "name": "John",
  "email": "John@gmail.com"
})
.execID()

>> INSERT INTO users (name, email) VALUES ("John", "John@gmail.com")
>> 1 # ID of new row is return
```
```
import allographer/QueryBuilder

RDB().table("users").insert(
  [
    %*{"name": "John", "email": "John@gmail.com", "address": "London"},
    %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
    %*{"name": "George", "email": "George@gmail.com", "address": "London"},
  ]
)
.exec()

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London"), ("Paul", "Paul@gmail.com", "London"), ("George", "George@gmail.com", "London")
```
```
import allographer/QueryBuilder

RDB().table("users").inserts(
  [
    %*{"name": "John", "email": "John@gmail.com", "address": "London"},
    %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
    %*{"name": "George", "birth_date": "1943-02-25", "address": "London"},
  ]
)
.exec()

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London")
>> INSERT INTO users (name, email, address) VALUES ("Paul", "Paul@gmail.com", "London")
>> INSERT INTO users (name, birth_date, address) VALUES ("George", "1960-1-1", "London")
```

### UPDATE
```
import allographer/QueryBuilder

RDB()
.table("users")
.where("id", "=", 100)
.update(%*{"name": "Mick", "address": "NY"})
.exec()

>> UPDATE users SET name = "Mick", address = "NY" WHERE id = 100
```

### DELETE
```
import allographer/QueryBuilder

RDB()
.table("users")
.delete(1)
.exec()

>> DELETE FROM users WHERE id = 1
```
```
import allographer/QueryBuilder

RDB()
.table("users")
.where("address", "=", "London")
.delete()
.exec()

>> DELETE FROM users WHERE address = "London"
```