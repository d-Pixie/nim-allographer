import os

# DB Connection
putEnv("DB_DRIVER", "sqlite")
putEnv("DB_CONNECTION", "/root/project/db.sqlite3")
# putEnv("DB_DRIVER", "mysql")
# putEnv("DB_CONNECTION", "mysql:3306")
# putEnv("DB_DRIVER", "postgres")
# putEnv("DB_CONNECTION", "postgres:5432")
putEnv("DB_USER", "user")
putEnv("DB_PASSWORD", "Password!")
putEnv("DB_DATABASE", "allographer")

# Logging
putEnv("LOG_IS_DISPLAY", "true")
putEnv("LOG_IS_FILE", "false")
putEnv("LOG_DIR", "/root/project/logs")
