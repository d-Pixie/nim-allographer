import os, parsecfg, terminal, logging
# include connection
from connection import getDriver, getConsoleLog, getFileLog, getLogDir

# file logging setting
let logConfigFile = getCurrentDir() & "/config/logging.ini"
try:
  let conf = loadConfig(logConfigFile)
  let isFileOutString = conf.getSectionValue("Log", "file")
  if isFileOutString == "true":
    let logPath = conf.getSectionValue("Log", "logDir") & "/log.log"
  # if getFileLog():
  #   let logPath = getLogDir() & "/log.log"
    createDir(parentDir(logPath))
    newRollingFileLogger(logPath, mode=fmAppend, fmtStr=verboseFmtStr).addHandler()
except:
  discard


proc driverTypeError*() =
  let driver = getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")


proc logger*(output: any, args:varargs[string]) =
  # get Config file
  let conf = loadConfig(logConfigFile)
  # console log
  let isDisplayString = conf.getSectionValue("Log", "display")
  if isDisplayString == "true":
  # if getConsoleLog():
    let logger = newConsoleLogger()
    logger.log(lvlInfo, $output & $args)
  # file log
  let isFileOutString = conf.getSectionValue("Log", "file")
  if isFileOutString == "true":
  # if getFileLog():
    info $output & $args


proc echoErrorMsg*(msg:string) =
  # console log
  styledWriteLine(stdout, fgRed, bgDefault, msg, resetStyle)
  # file log
  let conf = loadConfig(logConfigFile)
  let isFileOutString = conf.getSectionValue("Log", "file")
  if isFileOutString == "true":
    let path = conf.getSectionValue("Log", "logDir") & "/error.log"
  # if getFileLog():
    # let path = getLogDir() & "/error.log"
    let logger = newRollingFileLogger(path, mode=fmAppend, fmtStr=verboseFmtStr)
    logger.log(lvlError, msg)
