#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinythemes)
source("system_setup.R")
source("word2vec.R")
ggplot2::theme_set(theme_bw())

keyterms <- readLines("data/keyterms.txt")
timesteps_li <- gsub("_", " ~ ", readLines("data/timesteps.txt"))
timesteps_li <- paste0(seq_along(timesteps_li), "_", timesteps_li)
timesteps_li <- lapply(timesteps_li, function(x) {
    x <- strsplit(x, "_")[[1]]
    ts <- x[1]
    rng <- x[2]
    tags$li(tags$span(ts, class = "timestep-num"), rng)
})
timesteps <- seq_along(timesteps_li)


# Define UI for application that draws a histogram
ui <- bootstrapPage(
    includeCSS("www/custom.css"),
    navbarPage(
        "TA Project Demo", theme = shinytheme("flatly"), collapsible = TRUE, selected = "詞向量",
        tabPanel(title = "詞頻", icon = icon("bar-chart")),
        tabPanel(title = "LSA", icon = icon("line-chart")),
        tabPanel(title = "詞向量", icon = icon("location-arrow"),
                 # Input
                 sidebarLayout(
                     sidebarPanel(
                         selectInput(
                             inputId = "keyterms",
                             label = "詞彙：",
                             choices = keyterms,
                             selected = keyterms[1:3],
                             multiple = TRUE,
                             width = NULL,
                             size = NULL),
                         selectInput(
                             inputId = "timesteps",
                             label = "時間點：",
                             choices = timesteps,
                             selected = timesteps[1:2],
                             multiple = TRUE,
                             width = NULL,
                             size = NULL),
                         checkboxGroupInput(
                             inputId = "source",
                             label = "來源：",
                             choices = c("微博" = "weibo", "PTT" = "ptt"),
                             selected = c("weibo", "ptt"),
                             inline = TRUE,
                             width = NULL),
                         HTML("<label>區間：</label>"),
                         uiOutput("selectedTimeStepStr")
                         ),
                     # Plot
                     mainPanel(plotOutput("word2vecPlot", width = "90%", height = "520px")))
                 ),
        tabPanel(title = "搭配詞", icon = icon("cloud", lib = "glyphicon")),
        tabPanel(title = "句法依存", icon = icon("table"))
    ),
    HTML('<span class="src-link" title="原始碼">
            <a href="https://github.com/rlads2021/TA-project" target="_blank" style="color:black">
                <i class="fab fa-github"></i>
            </a>
          </span>')
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    output$word2vecPlot <- renderPlot({
        embed_viz(
            words = input$keyterms,
            timesteps = input$timesteps,
            source = input$source
        )
    })
    
    output$selectedTimeStepStr <- renderUI({
        tags$ul(timesteps_li[as.integer(input$timesteps)], class = "timesteps")
    })
}

# Run the application
shinyApp(ui = ui, server = server)
