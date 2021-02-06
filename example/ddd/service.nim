import json
import ../../src/allographer/query_builder
import repository

type Service = ref object
  repository:Repository

proc newService*():Service =
  return Service(
    repository: newRepository()
  )

proc getUsers*(this:Service):seq[JsonNode] =
  return this.repository.getUsers()

proc getUser*(this:Service, id:int):JsonNode =
  return this.repository.getUser(id)
