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
source("plot_dendrogram.R")
source("plot_network.R")
source("wordfreq_viz.R")
ggplot2::theme_set(theme_bw())


# Get keyterms
keyterms <- readLines("data/keyterms.txt")
# Get time step info
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
        "TA Project Demo", theme = shinytheme("flatly"), collapsible = TRUE, selected = "詞頻",
        tabPanel(title = "詞頻", icon = icon("bar-chart"),
                 sidebarLayout(
                     sidebarPanel(
                         textInput(
                             inputId = "wordfreq_selected_words", 
                             label = "詞彙：", 
                             value = "美國, 臺灣, 中國"
                         ),
                     ),
                     # Plot
                     mainPanel(
                         plotOutput("wordfreqPlot", width = "90%", height = "680px")
                         )
                     )
                 ),
        tabPanel(title = "LSA", icon = icon("line-chart"),
                 # Input
                 sidebarLayout(
                     sidebarPanel(
                         selectInput(
                             inputId = "timesteps2",
                             label = "時間點：",
                             choices = timesteps,
                             selected = timesteps[1:2],
                             multiple = TRUE,
                             width = NULL,
                             size = NULL),
                         # Set sample post number
                         sliderInput(
                            inputId = "samplePostNum",
                            label = "文章數",
                            min = 1, max = 85, step = 1,
                            value = 10
                         ),
                         checkboxGroupInput(
                             inputId = "source2",
                             label = "來源：",
                             choices = c("微博" = "weibo", "PTT" = "ptt"),
                             selected = c("weibo", "ptt"),
                             inline = TRUE,
                             width = NULL),
                         HTML("<label>區間：</label>"),
                         uiOutput("selectedTimeStepStr2")
                         ),
                     # Plot
                     mainPanel(
                         plotOutput("lsaDendroPlot", width = "98%", height = "520px"),
                         plotOutput("lsaNetworkPlot", width = "98%", height = "520px")
                         )
                     )
                 ),
        tabPanel(title = "詞向量", icon = icon("location-arrow"),
                 # Input
                 sidebarLayout(
                     sidebarPanel(
                        textInput(
                             inputId = "keyterms", 
                             label = "詞彙：", 
                             value = "美國, 臺灣"
                         ),
                         selectInput(
                             inputId = "timesteps",
                             label = "時間點：",
                             choices = timesteps,
                             selected = timesteps[6:8],
                             multiple = TRUE,
                             width = NULL,
                             size = NULL),
                         HTML("<label>區間：</label>"),
                         uiOutput("selectedTimeStepStr")
                         ),
                     # Plot
                     mainPanel(plotOutput("word2vecPlot", width = "100%", height = "580px")))
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
    # Word embedding
    output$word2vecPlot <- renderPlot({
        words <- strsplit(input$keyterms, ",")[[1]]
        embed_viz(
            search_terms = trimws(words),
            timesteps = input$timesteps
        )
    })
    output$selectedTimeStepStr <- renderUI({
        tags$ul(timesteps_li[as.integer(input$timesteps)], class = "timesteps")
    })
    
    # LSA
    output$lsaNetworkPlot <- renderPlot({
        plot_network_shiny(
            timesteps = input$timesteps2,
            n = input$samplePostNum,
            src = input$source2
        )
    })
    output$lsaDendroPlot <- renderPlot({
        plot_dendrogram_shiny(
            timesteps = input$timesteps2,
            n = input$samplePostNum,
            src = input$source2
        )
    })
    output$selectedTimeStepStr2 <- renderUI({
        tags$ul(timesteps_li[as.integer(input$timesteps2)], class = "timesteps")
    })
    
    # Word Frequency
    output$wordfreqPlot <- renderPlot({
        words <- strsplit(input$wordfreq_selected_words, ",")[[1]]
        freq_viz(words = trimws(words))
    })

}

# Run the application
shinyApp(ui = ui, server = server)
