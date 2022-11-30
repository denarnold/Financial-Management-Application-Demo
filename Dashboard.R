##---------------------------------------------------------------
##                LOAD PACKAGES INTO LIBRARY                   --
##---------------------------------------------------------------

library(shiny)          #used to run the web environment
library(RSQLite)        #used to connect to sqlite database
library(rhandsontable)  #used to make editable, excel-like tables
library(plotly)         #used to render graphs


setwd("Dashboard/")


source("process_dataframes.R")	#creates net worth plot object
source("plot_net_worth.R")	#creates net worth plot object
source("plot_account_trends.R") #creates simple plot objects for banking, investment, and crypto


##---------------------------------------------------------------
##                         Functions                           --
##---------------------------------------------------------------

#A function for formatting values as currency
#Input = string or list; Output = list
formatAsCurrency <- function(values) {
    
  values <- paste0(
    "$",
    format(
      x = round(values, 2),  #round to 2 decimal places
      big.mark=",",          #add thousands comma
      scientific=FALSE,      #don't show in scientific notation
      trim = TRUE            #don't add extra spaces
    )
  )
  
  #Change any negative values from "$-" to "-$"  
  lapply(
    X = values,
    FUN = function(t) {
      sub(x = t, pattern = "\\$-", replacement = "-\\$")
    }
  )
}




##---------------------------------------------------------------
##                      Shiny Part 1: UI                       --
##---------------------------------------------------------------

ui <- navbarPage("Finance Dashboard",

                 
                 
                   
  ##                      Create "Summary" Page
  ##...............................................................
  
  tabPanel("Summary",
    
    fluidRow(
      column(width = 2,
        #Balance table for bank accounts
        wellPanel(
          h3(textOutput("bankBalTotal")),
          plotlyOutput("simpleBankPlot", height = "25px"),
          br(),
          tableOutput("bankBal")
        )
      ),


      column(5,
        #Balance table for investment_1
        wellPanel(
          h3(textOutput("investment_1BalTotal")),
          plotlyOutput("simpleInvestmentPlot", height = "25px"),
          br(),
          tableOutput("investment_1Bal")
        )
      ),


      column(2,
        #Balance table for crypto
        wellPanel(
          h3(textOutput("bitcoinCurrentValue")),
          plotlyOutput("simpleCryptoPlot", height = "25px")
        )
      )
    ),
  
    
    #display the Net Worth graph
    #(height does not auto scale like width, so I set it manually)
    plotlyOutput("netWorthPlot", height = "600px"),
    p("*values are the most recent running totals for each month", style = "color: gray; font-style: italic"),
  ),
  
  
  
                 
  ##                    Create "Records" Page
  ##...............................................................
  
  tabPanel("Records",
           
    #top input row
    fluidRow(
     
      #create a dropdown list to select an account  
      column(width = 2,    
        selectInput("selectedAccount", label = "Account",
          choices = list("Visa" = "Visa_7651",
            "Checking" = "Checking_4883",
            "Savings" = "Savings_6893"))
      ),

      #display the account balance
      column(width = 2,
        print(strong("Balance:")),
        verbatimTextOutput("balance")
      ),
     
      #create a dropdown list for how many rows to load
      column(width = 2,
        selectInput("rowsToLoad", label = "Rows to display",
          choices = list("50" = "LIMIT 50",
            "All" = " ")
        )
      ),
     
      #create a search box
      column(width = 2,
        textInput("search", label = "Search")
      ),
    ),
    
    #display the rhandsontable
    rHandsontableOutput("table")
  )
)




##---------------------------------------------------------------
##                  Shiny Part 2: Server Logic                 --
##---------------------------------------------------------------

server <- function(input, output, session) {
  
  #connect to database using RSQLite package
  dbConnection <- dbConnect(RSQLite::SQLite(), "../SQLite Database/Sample Finance Records.db")
    
  
  
  
  ##                     Summary Page
  ##...............................................................
  
  # Bank ----------------------------------------------------------
  
  #create the bank header output
  output$bankBalTotal <- renderText(paste("Bank:", formatAsCurrency(bankBalTotal)))
  
  #format the Balance column as currency
  bankBal$Balance <- formatAsCurrency(bankBal$Balance)
  
  #render the bankBal dataframe as a table
  output$bankBal <- renderTable(bankBal, align = 'lr')
  
  
  
  
  # Investment ----------------------------------------------------------
  
  #create the bank header output
  output$investment_1BalTotal <- renderText(paste("Primary Investment Account:", formatAsCurrency(investment_1BalTotal)))
  
  #format the percentage column
  investment_1Bal$Percentage <- sprintf("%.0f%%", 100 * investment_1Bal$Percentage)
  
  #format the Balance column as currency
  investment_1Bal$Balance <- formatAsCurrency(investment_1Bal$Balance)
  
  #render the investment_1Bal dataframe as a table
  output$investment_1Bal <- renderTable(investment_1Bal, align = 'lrr')
  
  
  
  
  # Bitcoin ----------------------------------------------------------
  
  #create the Bitcoin header output (bitcoinCurrentValue variable from net_worth.R)
  output$bitcoinCurrentValue <- renderText(paste("Bitcoin:", formatAsCurrency(bitcoinCurrentValue)))

  
  

  # Render Plots ----------------------------------------------------------
  
  #render the netWorth plot from net_worth.R
  output$netWorthPlot <- renderPlotly({netWorthPlotObject})
  
  #render simple bank plot from simple_plots.R
  output$simpleBankPlot <- renderPlotly({simpleBankPlotObject})
  
  #render simple investment plot from simple_plots.R
  output$simpleInvestmentPlot <- renderPlotly({simpleInvestmentPlotObject})
  
  #render simple crypto plot from simple_plots.R
  output$simpleCryptoPlot <- renderPlotly({simpleCryptoPlotObject})
  
  
  
  
  ##                     Records Page
  ##...............................................................
  
  #Import categories table as a dataframe, then convert it to a vector so it can work as a dropdown field in rhandsontable.
  #  Delete the dataframe after the conversion.
  categoriesDF <- dbGetQuery(dbConnection, "SELECT categories FROM Categories ORDER BY (categories)")
  categoriesVector <- categoriesDF[["categories"]]
  remove(categoriesDF)
  
  
  #reactive function to import sql records
  re_import_sql <- reactive({
    
    #import the selected sql table as a dataframe
    sqlTableImport <- dbGetQuery(
      dbConnection,
      paste("SELECT transID, transDate, transDescription, transMemo, transCategory, transAmount, transReconciled",
            "FROM", input$selectedAccount,
            
            #insert a WHERE statement if there is text in the search box. Specify each column to search.
            if (input$search != "") {
              paste0(
                "WHERE transDate LIKE ", "'%", input$search, "%'",
                " OR transDescription LIKE ", "'%", input$search, "%'",
                " OR transMemo LIKE ", "'%", input$search, "%'",
                " OR transCategory LIKE ", "'%", input$search, "%'",
                " OR transAmount LIKE ", "'%", input$search, "%'"
              )
            },
            
            "ORDER BY transID DESC",
            input$rowsToLoad
           )
    )

    #reformat the transReconciled column in the dataframe to read as TRUE/FALSE instead of 0/1
    sqlTableImport$transReconciled <- as.logical(sqlTableImport$transReconciled)
    
    #return the table
    return(sqlTableImport)
  })
  
  
  #reactive function to create the handsontable, feeding in the table from re_import_sql as the source
  re_create_handsontable <- reactive({

    #feed in the sql dataframe by requesting the re_import_sql function above
    rhandsontable(re_import_sql()) %>%

      #display transAmount as currency
      hot_col("transAmount", format = "$0,0.00") %>%

      #don't limit certain columns to dropdown lists
      hot_col(col = "transMemo", type = "autocomplete", strict = FALSE) %>%
      hot_col(col = "transDescription", type = "autocomplete", strict = FALSE) %>%

      #define dropdown list for transCategory
      hot_col(col = "transCategory", type = "dropdown", source = categoriesVector) %>%

      #make some columns read-only and hide some with width=1
      hot_col("transID", readOnly = TRUE) %>%
      hot_col("transDate", readOnly = TRUE) %>%
      hot_col("transAmount", readOnly = TRUE)
  })
  
  
  #reactive function to calculate balance using a SQL query
  re_balance <- reactive({
    
    #import the selected sql table as a dataframe
    dbGetQuery(
      dbConnection,
      paste("SELECT SUM(transAmount) FROM", input$selectedAccount)
    )
  })
  

  #render the rhandsontable
  output$table <- renderRHandsontable({re_create_handsontable()})

  #render the account balance and format appropriately
  #since renderText needs a string input, need to convert formatAsCurrency output from a list to a string
  output$balance <- renderText(formatAsCurrency(re_balance()) %>% toString())
  
  #when a tibble is changed, save it to the sql database
  observeEvent(input$table$changes$changes, {
    
    #export the rhandsontable to a dataframe
    rhotDF <- hot_to_r(input$table)
    
    #create variables for the update
      headerList <- colnames(rhotDF) #used to get changeColumnName
      changeColumnIndex <- input$table$changes$changes[[1]][[2]] #used to get changeColumnName
    changeColumnName <- headerList[[changeColumnIndex+1]]
      changeRow <- input$table$changes$changes[[1]][[1]]+1 #used to get changeTransID
    changeTransID <- rhotDF[changeRow,1] #%>% print()
    #changeOldValue <- input$table$changes$changes[[1]][[3]]
    changeNewValue <- input$table$changes$changes[[1]][[4]]

          
    # Format changeNewValue so that it passes to sql properly ----------------------------------------------------------
    
    #if a transReconciled value changes to FALSE, send as a 0
    if (changeColumnName == "transReconciled" && changeNewValue == FALSE) {changeNewValue = 0}
    #if a transReconciled value changes to TRUE, send as a 1
    else if (changeColumnName == "transReconciled" && changeNewValue == TRUE) {changeNewValue = 1}
    
    #for everything else:
    else if (changeColumnName != "transReconciled") {
      #escape any apostrophes in the new value by doubling them ('')
      changeNewValue = gsub("'", "''", changeNewValue)
      #put quotes around the new value to pass to sql as a string
      changeNewValue = paste0("\'", changeNewValue, "\'")
    }

    #Assemble the string to pass to the query. Paste() combines elements and separates them with a space.
    updateQueryString <- paste("UPDATE", input$selectedAccount, "SET", changeColumnName, "=", changeNewValue, "WHERE transID =", changeTransID)
    
    #view the rendered sql query (for debugging)
    print(updateQueryString)

    #execute the rendered sql query.
    dbExecute(dbConnection, updateQueryString)
  })
  
  
  
  
  ##                             Other
  ##...............................................................
  
  #close the database connection and stop the app when the session ends (browser window closes)
  session$onSessionEnded(function() {
    dbDisconnect(dbConnection)
    stopApp()
  })
  
}




##---------------------------------------------------------------
##                  Shiny Part 3: Run Shiny App                --
##---------------------------------------------------------------

shinyApp(ui, server)