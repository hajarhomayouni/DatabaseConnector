library(DatabaseConnector)

# Test MySQL:
connectionDetails <- createConnectionDetails(dbms = "mysql",
                                             server = "localhost",
                                             user = "root",
                                             password = pw,
                                             schema = "fake_data")
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
dbDisconnect(conn)

# Test PDW with integrated security:
connectionDetails <- createConnectionDetails(dbms = "pdw",
                                             server = "JRDUSAPSCTL01",
                                             port = 17001,
                                             schema = "CDM_Truven_MDCR")
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
dbDisconnect(conn)

# CTAS hack stuff:
n <- 50
data <- data.frame(x = 1:n, y = runif(n))
insertTable(conn, "#temp", data, TRUE, TRUE, TRUE)

data <- querySql(conn, "SELECT TOP 10000 * FROM condition_occurrence")
data <- data[, c("PERSON_ID",
                 "CONDITION_CONCEPT_ID",
                 "CONDITION_START_DATE",
                 "CONDITION_END_DATE",
                 "CONDITION_TYPE_CONCEPT_ID",
                 "CONDITION_SOURCE_VALUE")]
insertTable(conn, "#temp", data, TRUE, TRUE, TRUE)


tableName <- "#temp"
dropTableIfExists <- TRUE
createTable <- TRUE
tempTable <- TRUE
oracleTempSchema <- NULL
connection <- conn
x <- querySql(conn, "SELECT * FROM #temp")
str(x)
# Test PDW without integrated security:
connectionDetails <- createConnectionDetails(dbms = "pdw",
                                             server = "JRDUSAPSCTL01",
                                             port = 17001,
                                             schema = "CDM_Truven_MDCR",
                                             user = "hix_writer",
                                             password = pw)
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
dbDisconnect(conn)

# Test SQL Server without integrated security:
connectionDetails <- createConnectionDetails(dbms = "sql server",
                                             server = "RNDUSRDHIT06.jnj.com",
                                             user = "mschuemi",
                                             domain = "eu",
                                             password = pw,
                                             schema = "cdm_hcup",
                                             port = 1433)
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
x <- querySql.ffdf(conn, "SELECT TOP 1000000 * FROM person")
dbDisconnect(conn)

# Test SQL Server with integrated security:
connectionDetails <- createConnectionDetails(dbms = "sql server",
                                             server = "RNDUSRDHIT06.jnj.com",
                                             schema = "cdm_hcup")
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
querySql.ffdf(conn, "SELECT TOP 100 * FROM person")
executeSql(conn, "CREATE TABLE #temp (x int)")
querySql(conn, "SELECT COUNT(*) FROM #temp")
# x <- querySql.ffdf(conn,'SELECT * FROM person')
data <- data.frame(id = c(1,2,3), date = as.Date(c("2000-01-01","2001-01-31","2004-12-31")), text = c("asdf","asdf","asdf"))
insertTable(connection = conn,
            tableName = "test",
            data = data,
            dropTableIfExists = TRUE,
            createTable = TRUE,
            tempTable = TRUE)
d2 <- querySql(conn, "SELECT * FROM #test")
str(d2)
dbDisconnect(conn)

# Test Oracle:
connectionDetails <- createConnectionDetails(dbms = "oracle",
                                             server = "xe",
                                             user = "system",
                                             password = pw,
                                             schema = "cdm_truven_ccae_6k")
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
dbDisconnect(conn)

# Test PostgreSQL:
pw <- Sys.getenv("pwPostgres")
connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                             server = "localhost/ohdsi",
                                             user = "postgres",
                                             password = pw,
                                             schema = "cdm4_sim")
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
dbDisconnect(conn)

# Test Redshift:
pw <- Sys.getenv("pwRedShift")
connectionDetails <- createConnectionDetails(dbms = "redshift",
                                             server = "hicoe.cldcoxyrkflo.us-east-1.redshift.amazonaws.com/truven_mdcr",
                                             port = "5439",
                                             user = "mschuemi",
                                             password = pw,
                                             schema = "cdm",
                                             extraSettings = "ssl=true&sslfactory=com.amazon.redshift.ssl.NonValidatingFactory")
conn <- connect(connectionDetails)
querySql(conn, "SELECT COUNT(*) FROM person")
executeSql(conn, "CREATE TABLE scratch.test (x INT)")

person <- querySql.ffdf(conn, "SELECT * FROM person")
data <- data.frame(id = c(1,2,3), date = as.Date(c("2000-01-01","2001-01-31","2004-12-31")), text = c("asdf","asdf","asdf"))
insertTable(connection = conn,
            tableName = "test",
            data = data,
            dropTableIfExists = TRUE,
            createTable = TRUE,
            tempTable = TRUE)
d2 <- querySql(conn, "SELECT * FROM test")
str(d2)

options('fftempdir' = 's:/fftemp')
d2 <- querySql.ffdf(conn, "SELECT * FROM test")
d2
dbDisconnect(conn)

### Tests for dbInsertTable ###
day.start <- "1900/01/01"
day.end <- "2012/12/31"
dayseq <- seq.Date(as.Date(day.start), as.Date(day.end), by = "day")
makeRandomStrings <- function(n = 1, lenght = 12) {
  randomString <- c(1:n)
  for (i in 1:n) randomString[i] <- paste(sample(c(0:9, letters, LETTERS), lenght, replace = TRUE),
                                          collapse = "")
  return(randomString)
}
data <- data.frame(start_date = dayseq,
                   person_id = as.integer(round(runif(length(dayseq), 1, 1e+07))),
                   value = runif(length(dayseq)),
                   id = makeRandomStrings(length(dayseq)))
str(data)
tableName <- "#temp"
connectionDetails <- createConnectionDetails(dbms = "sql server",
                                             server = "RNDUSRDHIT06.jnj.com",
                                             schema = "cdm_hcup")
connection <- connect(connectionDetails)
dbInsertTable(connection, tableName, data, dropTableIfExists = TRUE)

d <- querySql(connection, "SELECT * FROM #temp")
d <- querySql.ffdf(connection, "SELECT * FROM #temp")

library(ffbase)
data <- as.ffdf(data)

dbDisconnect(connection)
