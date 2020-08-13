import strformat, json, progress
import bcrypt
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
# import allographer/query_builder
# import allographer/schema_builder


# マイグレーション
schema([
  table("auth",[
    Column().increments("id"),
    Column().string("auth")
  ], reset=true),
  table("users",[
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().string("email").nullable(),
    Column().string("password").nullable(),
    Column().string("salt").nullable(),
    Column().string("address").nullable(),
    Column().date("birth_date").nullable(),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])

# シーダー
rdb().table("auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])

# プログレスバー
let total = 50
var pb = newProgressBar(total=total) # totalは分母

pb.start()
var insertData: seq[JsonNode]
for i in 1..total:
  let salt = genSalt(10)
  let password = hash(&"password{i}", salt)
  let authId = if i mod 2 == 0: 1 else: 2
  insertData.add(
    %*{
      "name": &"user{i}",
      "email": &"user{i}@gmail.com",
      "password": password,
      "salt": salt,
      "auth_id": authId
    }
  )
  pb.increment()

pb.finish()
rdb().table("users").insert(insertData)
