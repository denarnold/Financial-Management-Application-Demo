##---------------------------------------------------------------
##                LOAD PACKAGES INTO LIBRARY                   --
##---------------------------------------------------------------

# #sourcing process_dataframes.R here will cause pulls to happen twice from Dashboard.R
#source("process_dataframes.R")


#set month range for plots
plotRange = 5


##---------------------------------------------------------------
##                    Simple Banking Plot                      --
##---------------------------------------------------------------

simpleBankPlotObject <- plot_ly(
  netWorthPlot,
  x = ~plotMonth,
  y = ~allBanking,
  width = 150, height = 25,
  type = 'scatter',
  mode = 'lines', #hide markers
  hovertemplate = '%{x|%B}, %{y:$,f}<extra></extra>', #choose hover text and specify the formatting
  line = list(shape = "linear", width = 2)  #shape=hvh for bargraph style, linear for regular, and spline for smoothed
) %>%
  
  layout(
    #make background transparent
    paper_bgcolor='rgba(0,0,0,0)',
    plot_bgcolor='rgba(0,0,0,0)',
    margin = list(t=0, r=0, b=0, l=0),  #make the graph take up the entire paper space
    
    xaxis = list(
      #zoom x axis to only show the plotRange number of months back
      range = c(
        netWorthPlot[nrow(netWorthPlot) - plotRange, ]$plotMonth,  #date x months ago
        netWorthPlot[nrow(netWorthPlot), ]$plotMonth),  #current month
      visible = FALSE,
      showgrid = FALSE,
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE),
    
    yaxis = list(
      #zoom y axis to min and max data values (add $300 buffer to prevent clipping)
      range = c(
        min(netWorthPlot[(nrow(netWorthPlot) - plotRange):(nrow(netWorthPlot)), ]$allBanking) - 300,
        max(netWorthPlot[(nrow(netWorthPlot) - plotRange):(nrow(netWorthPlot)), ]$allBanking) + 300
      ),
      visible = FALSE,
      showgrid = FALSE,
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE)
  ) %>%
  
  config(displayModeBar = FALSE)




##---------------------------------------------------------------
##                    Simple Investment Plot                     --
##---------------------------------------------------------------

simpleInvestmentPlotObject <- plot_ly(
  netWorthPlot,
  x = ~plotMonth,
  y = ~investment_1Plot,
  width = 150, height = 25,
  type = 'scatter',
  mode = 'lines', #hide markers
  hovertemplate = '%{x|%B}, %{y:$,f}<extra></extra>', #choose hover text and specify the formatting
  line = list(shape = "linear", width = 2)  #shape=hvh for bargraph style, linear for regular, and spline for smoothed
) %>%
  
  layout(
    #make background transparent
    paper_bgcolor='rgba(0,0,0,0)',
    plot_bgcolor='rgba(0,0,0,0)',
    margin = list(t=0, r=0, b=0, l=0),  #make the graph take up the entire paper space
    
    xaxis = list(
      #zoom x axis to only show the plotRange number of months back
      range = c(
        netWorthPlot[nrow(netWorthPlot) - plotRange, ]$plotMonth,  #date x months ago
        netWorthPlot[nrow(netWorthPlot), ]$plotMonth),  #current month
      visible = FALSE,
      showgrid = FALSE,
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE),
    
    yaxis = list(
      #zoom y axis to min and max data values (add $20 buffer to prevent clipping)
      range = c(
        min(netWorthPlot[(nrow(netWorthPlot) - plotRange):(nrow(netWorthPlot)), ]$investment_1Plot) - 20,
        max(netWorthPlot[(nrow(netWorthPlot) - plotRange):(nrow(netWorthPlot)), ]$investment_1Plot) + 20
      ),
      visible = FALSE,
      showgrid = FALSE,
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE)
  ) %>%
  
  config(displayModeBar = FALSE)




##---------------------------------------------------------------
##                 Simple Cryptocurrency Plot                  --
##---------------------------------------------------------------

simpleCryptoPlotObject <- plot_ly(
  netWorthPlot,
  x = ~plotMonth,
  y = ~allCrypto,
  width = 150, height = 25,
  type = 'scatter',
  mode = 'lines', #hide markers
  hovertemplate = '%{x|%B}, %{y:$,f}<extra></extra>', #choose hover text and specify the formatting
  line = list(shape = "linear", width = 2)  #shape=hvh for bargraph style, linear for regular, and spline for smoothed
) %>%
  
  layout(
    #make background transparent
    paper_bgcolor='rgba(0,0,0,0)',
    plot_bgcolor='rgba(0,0,0,0)',
    margin = list(t=0, r=0, b=0, l=0),  #make the graph take up the entire paper space
    
    xaxis = list(
      #zoom x axis to only show the plotRange number of months back
      range = c(
        netWorthPlot[nrow(netWorthPlot) - plotRange, ]$plotMonth,  #date x months ago
        netWorthPlot[nrow(netWorthPlot), ]$plotMonth),  #current month
      visible = FALSE,
      showgrid = FALSE,
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE),
    
    yaxis = list(
      #zoom y axis to min and max data values (add $20 buffer to prevent clipping)
      range = c(
        min(netWorthPlot[(nrow(netWorthPlot) - plotRange):(nrow(netWorthPlot)), ]$allCrypto) - 20,
        max(netWorthPlot[(nrow(netWorthPlot) - plotRange):(nrow(netWorthPlot)), ]$allCrypto) + 20
      ),
      visible = FALSE,
      showgrid = FALSE,
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE)
  ) %>%
  
  config(displayModeBar = FALSE)