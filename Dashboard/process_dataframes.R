##---------------------------------------------------------------
##                LOAD PACKAGES INTO LIBRARY                   --
##---------------------------------------------------------------

library(tidyr)          #used to fill NA values based on the previous entry in investment plot dataframes
library(quantmod)       #used for retrieving stock prices
library(lubridate)      #used for finding the last day of every month (bitcoin dateframe)
library(dplyr)          #use rename function to rename a column

#load other R scripts
source("database_to_dataframes.R")	#creates banking and investment dataframes

#disable printing in scientific notation
options(scipen=999)

#disable quantmod warning about version changes
options("getSymbols.warning4.0"=FALSE)




##---------------------------------------------------------------
##                  Modify Investment Dataframes                 --
##---------------------------------------------------------------

#create a function to prepare dataframes to plot for each investment account
create_investment_plot_df <- function(investmentAccount) {

  
  
    
  ##                    Clean the input
  ##............................................................... 
  
  #create a dataframe to prepare records before plotting
  cleanDf <- investmentAccount
  
  #delete all records where the quantityRunningTotal is NA
  cleanDf <- cleanDf[!is.na(cleanDf$quantityRunningTotal),]
  
  #add a column to state the month in which each transaction takes place, so they can be grouped by month
  cleanDf$plotMonth <- as.Date(cut(cleanDf$transDate, breaks = "month"))
  
  #group by month, listing the most recent running total
  #  n specifies how many rows the tail function should pull
  cleanDf <- aggregate(
    cleanDf,
    by = list(cleanDf$plotMonth, cleanDf$securitySymbol),
    FUN = tail,
    n = 1)
  
  #only keep relevant columns
  cleanDf <- cleanDf[, c("plotMonth", "securitySymbol", "securityDescription", "quantityRunningTotal")]
  
  #create a list of securities listed within investmentAccount
  securityNames <- unique(na.omit(cleanDf$securitySymbol))
  
  #create variables for the first month of the data range and the current month
  startMonth <- head(cleanDf$plotMonth, n=1)
  currentMonth <- as.Date(format(Sys.Date(),"%Y-%m-01"))
  
  
  

  ##                    Retrieve stock prices
  ##...............................................................  
  
  #create an environment to store xts security objects
  securityXTSEnv <- new.env()
  
  #retrieve stock prices for securities in the securityNames list
  getSymbols(
    securityNames,
    from = startMonth,
    to = Sys.Date(),  #using "currentMonth" cuts it short, better to just use today
    env = securityXTSEnv)
  
  #combine all xts objects located in securityXTSEnv into a dataframe, keeping only the Close columns
  combinedSecurityXTS <- as.data.frame(do.call(merge, c(eapply(securityXTSEnv, Cl))))
  
  #remove ".Close" from the column names so that they are just the security symbol
  colnames(combinedSecurityXTS) <- sub("\\..*", "", colnames(combinedSecurityXTS))
  
  #the dates copied over as the row names. transfer them to a column instead
  combinedSecurityXTS <- cbind(
    date = as.Date(rownames(combinedSecurityXTS)),
    data.frame(combinedSecurityXTS, row.names = NULL))
  
  #add a column to state the month in which each transaction takes place, so they can be grouped by month
  combinedSecurityXTS$plotMonth <- as.Date(cut(combinedSecurityXTS$date, breaks = "month"))
  
  #group by month, listing the most recent price
  #  n specifies how many rows the tail function should pull
  combinedSecurityXTS <- aggregate(
    combinedSecurityXTS,
    by = list(combinedSecurityXTS$plotMonth),
    FUN = tail,
    n = 1)
  
  #only keep relevant columns
  combinedSecurityXTS <- subset(combinedSecurityXTS, select = -c(Group.1, date))
  
  
  
  
  ##            Compile records into a plotable dataframe
  ##............................................................... 
  
  #create a dataframe listing all the months to plot
  investmentMonthsDf <- data.frame("plotMonth" = seq(startMonth, currentMonth, by="month"))
  
  #create empty dataframe to plot
  # (in order to append records later, column names must match. data types will be overwritten during the append, so they don't really matter here)
  plotDf <- data.frame(plotMonth = character(), securitySymbol = character(), securityDescription = character(), valueRunningTotal = numeric())
  
  #process and add each security to plotDf
  for (securityName in securityNames) {
    
    #join records for each security with investmentMonthsDf
    securityDf <- merge(
      x = subset(cleanDf, securitySymbol == securityName),
      y = investmentMonthsDf,
      by = "plotMonth",
      all.y = TRUE)
    
    #fill in records for securitySymbol, securityDescription, and quantityRunningTotal for months where no activity took place
    # (uses "fill" from tidyr package)
    securityDf <- fill(data = securityDf, securitySymbol, securityDescription, quantityRunningTotal)
      
    #insert scraped prices for the current security
    securityDf <- merge(
      x = securityDf,
      #create a subset of combinedSecurityXTS for for an easy merge. change the column name to "scrapedSecurityPrice"
      y = subset(combinedSecurityXTS, select = c("plotMonth", securityName)) %>% rename(c("scrapedSecurityPrice" = 2)),
      by = "plotMonth"
    )
    
    #add a valueRunningTotal column
    securityDf$valueRunningTotal <- securityDf$quantityRunningTotal * securityDf$scrapedSecurityPrice
    
    #drop the scrapedSecurityPrice column
    securityDf <- subset(securityDf, select = -c(scrapedSecurityPrice))
    
    #append to the plotDf dataframe
    plotDf <- rbind(securityDf, plotDf)
  }

  
  #add all the securities together for each month
  as.data.frame(xtabs(valueRunningTotal ~ plotMonth, plotDf))
  
  #return plotDf
  return(plotDf)
  
}

#run the two investment accounts through the create_investment_plot_df function
investment_1Plot <- create_investment_plot_df(investment_1)
investment_2Plot <- create_investment_plot_df(investment_2)




##            Current investment_1 balance
##............................................................... 

### consider making this into a function and running investment_2 through it as well, then update the last row
###  of netWorthPlot like is done with investment_1.

#aggregate investment_1Plot by security, selecting the last valueRunningTotal for each security
investment_1Bal <- aggregate(investment_1Plot, by = list(investment_1Plot$securitySymbol), FUN = tail, n = 1)

#only keep relevant columns
investment_1Bal <- subset(investment_1Bal, select = c("securitySymbol", "securityDescription", "quantityRunningTotal"))

#remove securities that have a balance of 0
investment_1Bal <- investment_1Bal[investment_1Bal$quantityRunningTotal != 0,]

#pull the current price for each security
investment_1Bal$price <- getQuote(investment_1Bal$securitySymbol)$Last

#calculate the value of each security
investment_1Bal$value <- investment_1Bal$quantityRunningTotal * investment_1Bal$price

#calculate each security's percentage of the entire portfolio
investment_1Bal$percentage <- investment_1Bal$value / sum(investment_1Bal$value)

#only keep relevant columns
investment_1Bal <- subset(investment_1Bal, select = c("securityDescription", "value", "percentage"))

#rename columns
names(investment_1Bal) <- c("Security", "Balance", "Percentage")

#sort by balance descending
investment_1Bal <- investment_1Bal[order(-investment_1Bal$Balance),]


#sum all securities for the total balance
investment_1BalTotal <- round(sum(investment_1Bal$Balance))




##---------------------------------------------------------------
##          Modify allCrypto Dataframe for Plotting            --
##---------------------------------------------------------------


##              Calculate current Bitcoin value
##...............................................................

#pull current price
bitcoinPrice <- jsonlite::fromJSON("https://api.coinbase.com/v2/prices/spot?currency=USD")
bitcoinPrice <- as.numeric(bitcoinPrice$data$amount)

#create variable for Bitcoins in portfolio
bitcoinOwned <- 0.03000000

#create variable for current value
bitcoinCurrentValue <- round(bitcoinPrice * bitcoinOwned)




##              Calculate missing Bitcoin values
##...............................................................

#create a dataframe for calculating new Bitcoin values (last day of each month since last allCrypto record)
newBitcoin <- data.frame(plotMonth = seq.Date(
  from = as.Date(ceiling_date(allCrypto$plotMonth[nrow(allCrypto)], unit = "month")),
  to = Sys.Date(),
  by = "month"))

#find the last day of each month (round up to the next month and subtract 1 day)
newBitcoin$date <- ceiling_date(newBitcoin$plotMonth, unit = "month") - 1

#import Bitcoin price history and convert dates
bitcoinPriceHistory <- read.csv(file = 'https://www.cryptodatadownload.com/cdd/Binance_BTCUSDT_d.csv', skip = 1)
bitcoinPriceHistory$date <- as.Date(bitcoinPriceHistory$date)

#copy over relevant closing prices
newBitcoin <- merge(newBitcoin, bitcoinPriceHistory[, c("date", "close")], all.x = TRUE, all.y = FALSE)

#calculate bitcoin values for each month
newBitcoin$value <- newBitcoin$close * bitcoinOwned

#fix the value for the current month to show the current value
newBitcoin$value[nrow(newBitcoin)] <- bitcoinCurrentValue

#append newBitcoin to allCrypto
allCrypto <- rbind(allCrypto, newBitcoin[, c("plotMonth", "value")])

#remove unused objects
remove(newBitcoin, bitcoinPriceHistory, bitcoinPrice, bitcoinOwned)




##---------------------------------------------------------------
##                    Create Cars Dataframe                    --
##---------------------------------------------------------------

#create a function for creating car dataframes
create_car_plot_df <- function(purchaseDate, purchasedValue, soldDate, soldValue) {
  
  #create a list of all the days between the purchase and sale date
  dateList <- seq(as.Date(purchaseDate, "%m/%d/%y"), as.Date(soldDate, "%m/%d/%y"), by = "day")
  
  #create the dataframe
  data.frame(
  'plotDate' = dateList,
  'value' = round(seq(purchasedValue, soldValue, length.out = length(dateList))))
}

#send each car through the create_car_plot_df function
carCorolla <- create_car_plot_df('08/01/11', 3000, '05/07/17', 1000)
carCamry <- create_car_plot_df('02/22/15', 500, '10/08/16', 800)
carAltima <- create_car_plot_df('02/01/17', 2000, Sys.Date(), 3100)

#create empty dataframe to plot
# (in order to append records later, column names must match. data types will be overwritten during the append, so they don't really matter here)
allCars <- data.frame(plotMonth = character(), value = numeric())

#combine all car dataframes into a single dataframe
allCars <- rbind(allCars, carCorolla)
allCars <- rbind(allCars, carCamry)
allCars <- rbind(allCars, carAltima)

#delete individual car dataframes
remove(carCorolla)
remove(carCamry)
remove(carAltima)

#combine the value of each car to get a single daily value
allCars <- aggregate(value ~ plotDate, allCars, sum)

#add a column to state the month, so records can be grouped by month
allCars$plotMonth <- as.Date(cut(allCars$plotDate, breaks = "month"))

#group records by month (use tail to show the most recent value for each month)
#n specifies how many rows the tail function should pull
allCars <- aggregate(value ~ plotMonth, allCars, FUN = tail, n = 1)




##---------------------------------------------------------------
##          Combine Dataframes to Create netWorthPlot          --
##---------------------------------------------------------------

#combine accounts into a single netWorthPlot dataframe
#values will show the most recent runningTotals for each month


##                       Investment_1
##...............................................................

#assign investment_1Plot to tempDf for manipulation
tempDf <- subset(investment_1Plot, select = c("plotMonth", "valueRunningTotal"))

#group records by month (use sum to add up all securities for each month)
tempDf <- aggregate(valueRunningTotal ~ plotMonth, tempDf, sum)

#insert into a plot dataframe
netWorthPlot <- tempDf

#drop tempDf
rm(tempDf)




##                        Investment_2
##...............................................................

#assign investment_2Plot to tempDf for manipulation
tempDf <- subset(investment_2Plot, select = c("plotMonth", "valueRunningTotal"))

#group records by month (use sum to add up all securities for each month)
tempDf <- aggregate(valueRunningTotal ~ plotMonth, tempDf, sum)

#insert into the plot dataframe
netWorthPlot <- merge(
  x = netWorthPlot,
  y = tempDf,
  by = "plotMonth",
  all = TRUE)

#drop tempDf
rm(tempDf)




##                          Banking
##...............................................................

#assign allBanking to tempDf for manipulation
tempDf <- subset(allBanking, select = c("transDate", "runningTotal"))

#add a column to state the month in which each transaction takes place, so they can be grouped by month
tempDf$plotMonth <- as.Date(cut(tempDf$transDate, breaks = "month"))

#group records by month (use tail to show the most recent runningTotal for each month - this is how
#  investment securities were initially aggregated)
#n specifies how many rows the tail function should pull
tempDf <- aggregate(runningTotal ~ plotMonth, tempDf, FUN = tail, n = 1)

#insert into the plot dataframe
netWorthPlot <- merge(
  x = netWorthPlot,
  y = tempDf,
  by = "plotMonth",
  all = TRUE)

#drop tempDf
rm(tempDf)




##                           Crypto
##...............................................................

#insert into the plot dataframe
netWorthPlot <- merge(
  x = netWorthPlot,
  y = allCrypto,
  by = "plotMonth",
  all = TRUE)




##                            Cars
##...............................................................

#insert into the plot dataframe
netWorthPlot <- merge(
  x = netWorthPlot,
  y = allCars,
  by = "plotMonth",
  all = TRUE)




##                          Cleanup
##...............................................................

#rename netWorthPlot column names
colnames(netWorthPlot) <- c("plotMonth","investment_1Plot", "investment_2Plot", "allBanking", "allCrypto", "allCars")

#change NA values to 0
netWorthPlot[is.na(netWorthPlot)] <- 0

#update last row with current values (fixes values of 0 on first day of month)
netWorthPlot[nrow(netWorthPlot),]$allBanking <- bankBalTotal
netWorthPlot[nrow(netWorthPlot),]$investment_1Plot <- investment_1BalTotal