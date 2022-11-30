##---------------------------------------------------------------
##                LOAD PACKAGES INTO LIBRARY                   --
##---------------------------------------------------------------

library(RSQLite)        #used to connect to sqlite database
library(readr)          #used to import the script of an sql file using the read_file() function

#disable printing in scientific notation
options(scipen=999)




##---------------------------------------------------------------
##                      All Bank Records                       --
##---------------------------------------------------------------

#connect to database using RSQLite package
dbConnection <- dbConnect(RSQLite::SQLite(), "../SQLite Database/Sample Finance Records.db")

#create an empty dataframe that others will merge into.
allBanking = data.frame()

#create a vector of existing sql tables
accountNames <- c('Checking_1358',
                  'Checking_4883',
                  'Checking_6659',
                  'Savings_6893',
                  'Savings_7182',
                  'Savings_8395',
                  'Visa_2774',
                  'Visa_5382',
                  'Visa_6358',
                  'Visa_7651')

#loop through the accountNames vector
for (accountName in accountNames) {
  
  #import records from the database
  tempDf <- dbGetQuery(
    dbConnection,
    paste('SELECT transID, transDate, transDescription, transMemo, transCategory, transAmount',
          'FROM ', accountName)
  )
  
  #add and populate a transAccount column to the tempDf
  tempDf$transAccount <- accountName
  
  #append records to allBanking
  allBanking <- rbind(allBanking, tempDf)
}

#remove unused objects
remove(tempDf, accountName, accountNames)

#close the SQL connection
dbDisconnect(dbConnection)

#convert transDate to the date datatype
allBanking$transDate <- as.Date(allBanking$transDate)

#reorder allBanking by date
allBanking <- allBanking[order(as.Date(allBanking$transDate)),]

#add a running total column to allBanking
allBanking$runningTotal <- round(cumsum(allBanking$transAmount), 2)




##---------------------------------------------------------------
##                        Bank Balance                         --
##---------------------------------------------------------------

#connect to database using RSQLite package
dbConnection <- dbConnect(RSQLite::SQLite(), "../SQLite Database/Sample Finance Records.db")

#create a dataframe containing balances for each bank account
bankBal <- data.frame(
  Account = c("Visa", "Checking", "Savings"),
  Balance = c(
    #dbGetQuery imports a dataframe even though here it is just returning a single value.
    #  Using [1,] at the end selects the first element as a string, which is what is needed here.
    dbGetQuery(dbConnection, "SELECT SUM(transAmount) FROM Visa_7651")[1,],
    dbGetQuery(dbConnection, "SELECT SUM(transAmount) FROM Checking_4883")[1,],
    dbGetQuery(dbConnection, "SELECT SUM(transAmount) FROM Savings_6893")[1,]
  )
)

#close the SQL connection
dbDisconnect(dbConnection)

#sum all accounts for the total balance
bankBalTotal <- round(sum(bankBal$Balance))




##---------------------------------------------------------------
##                   Investment Accounts                       --
##---------------------------------------------------------------

#connect to database using RSQLite package
dbConnection <- dbConnect(RSQLite::SQLite(), "../SQLite Database/Sample Finance Records.db")

#import records from the Investment_1 table in the database
#skip "SPAXX". the sum will always be 0 but the quantityRunningTotal would indicate otherwise
investment_1 <- dbGetQuery(
  dbConnection,
  "SELECT transID, transDate, transDescription, securitySymbol, securityDescription, transQuantity, securityPrice, transAmount
  FROM Investment_1
  WHERE securitySymbol != 'SPAXX'"
)

#import records from the Investment_2 table in the database
investment_2 <- dbGetQuery(
  dbConnection,
  "SELECT transID, transDate, transDescription, securitySymbol, securityDescription, transQuantity, securityPrice, transAmount
  FROM Investment_2"
)

#close the SQL connection
dbDisconnect(dbConnection)

#convert transDate to the date datatype for both dataframes
investment_1$transDate <- as.Date(investment_1$transDate)
investment_2$transDate <- as.Date(investment_2$transDate)

# change NA to 0 for the transQuantity column. This is so cumsum will work when creating running totals.
investment_1$transQuantity[is.na(investment_1$transQuantity)] <- 0
investment_2$transQuantity[is.na(investment_2$transQuantity)] <- 0

#add security quantity running total columns for the quantity of each security. Round to 3 decimal places
investment_1$quantityRunningTotal <- round(
  ave(investment_1$transQuantity, investment_1$securitySymbol, FUN=cumsum),
  3)

investment_2$quantityRunningTotal <- round(
  ave(investment_2$transQuantity, investment_2$securitySymbol, FUN=cumsum),
  3)

#change 0 back to NA for transQuantity and quantityRunningTotal columns
#use transQuantity == 0 to gauge which rows should be set to NA
investment_1$quantityRunningTotal[investment_1$transQuantity == 0] <- NA
investment_1$transQuantity[investment_1$transQuantity == 0] <- NA

investment_2$quantityRunningTotal[investment_2$transQuantity == 0] <- NA
investment_2$transQuantity[investment_2$transQuantity == 0] <- NA




##---------------------------------------------------------------
##                       Cryptocurrency                        --
##---------------------------------------------------------------

#connect to database using RSQLite package
dbConnection <- dbConnect(RSQLite::SQLite(), "../SQLite Database/Sample Finance Records.db")

#import records from the Cryptocurrency table in the database
allCrypto <- dbGetQuery(dbConnection, "SELECT * FROM Cryptocurrency")

#close the SQL connection
dbDisconnect(dbConnection)

#convert dates
allCrypto$plotMonth <- as.Date(allCrypto$plotMonth)




#remove database connection object
remove(dbConnection)