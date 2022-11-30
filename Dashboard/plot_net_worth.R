##---------------------------------------------------------------
##                LOAD PACKAGES INTO LIBRARY                   --
##---------------------------------------------------------------

library(plotly)         #used to create graphs


# #sourcing process_dataframes.R here will cause pulls to happen twice from Dashboard.R
#source("process_dataframes.R")


##---------------------------------------------------------------
##              Plot Net Worth as Stacked Bar Chart            --
##---------------------------------------------------------------

#plot using plotly
netWorthPlotObject <- plot_ly(
  netWorthPlot,
  x = ~plotMonth,
  y = ~allCars,
  name = 'Cars',
  type = 'scatter',
  stackgroup = 'one',
  #choose hover text and specify the formatting
  #  https://github.com/d3/d3-time-format
  #  https://github.com/d3/d3-3.x-api-reference/blob/master/Formatting.md#d3_format
  hovertemplate = '%{x|%b %Y}, %{y:$,f}',
  mode = 'lines', #hide markers
  line = list(shape = "linear", width = 0), #shape=hvh for bargraph style, linear for regular, and spline for smoothed
  fillcolor = 'rgb(63,115,136)',
  visible = 'legendonly') %>%
  
  add_trace(
    y = ~allCrypto,
    name = 'Crypto',
    fillcolor = 'rgb(39,127,142)',
    visible = TRUE) %>%
  
  add_trace(
    y = ~investment_2Plot,
    name = 'Retirement Investment Account',
    fillcolor = 'rgb(42,135,130)',
    visible = 'legendonly') %>%
  
  add_trace(
    y = ~investment_1Plot,
    name = 'Primary Investment Account',
    fillcolor = 'rgb(31,161,135)',
    visible = TRUE) %>%
  
  add_trace(
    y = ~allBanking,
    name = 'Bank',
    fillcolor = 'rgb(74,193,109)',
    visible = TRUE) %>%
  
  layout(
    xaxis = list(title = ''),
    yaxis = list(title = '')
  )
