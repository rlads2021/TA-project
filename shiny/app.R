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
library(patchwork)
source("system_setup.R")
source("word2vec.R")
source("plot_dendrogram.R")
source("plot_network.R")
source("wordfreq_viz.R")
source("dependency.R")
source("collocation_viz.R")
source("topic_viz.R")
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
        "兩岸社群媒體中的臺灣形象", theme = shinytheme("flatly"), collapsible = TRUE, selected = "詞頻",
        tabPanel(title = "詞頻", icon = icon("bar-chart"),
                 sidebarLayout(
                     sidebarPanel(
                         textInput(
                             inputId = "wordfreq_selected_words", 
                             label = "詞彙：", 
                             value = "美國, 臺灣, 中國"
                         ),
                         HTML("<label>區間：</label>"),
                         uiOutput("selectedTimeStepStrWordfreq")
                     ),
                     # Plot
                     mainPanel(
                         plotOutput("wordfreqPlot", width = "100%", height = "680px")
                         )
                     )
                 ),
        tabPanel(title = "搭配詞", icon = icon("project-diagram"),
                 sidebarLayout(
                     sidebarPanel(
                         textInput(
                             inputId = "keytermCollo", 
                             label = "詞彙 (只能輸入一個)：", 
                             value = "臺灣"
                         ),
                         sliderInput(
                           inputId = "timestepsCollo",
                           label = "時間：",
                           min = min(timesteps),
                           max = max(timesteps),
                           value = c(6, 8),
                           step = 1, round = T
                         ),
                         sliderInput(
                            inputId = "numOfCollo",
                            label = "Top n：",
                            min = 5,
                            max = 30,
                            value = 10,
                            step = 1,
                            round = T
                         ), 
                         HTML("<label>區間：</label>"),
                         uiOutput("selectedTimeStepStrCollo")
                     ),
                     # Plot
                     mainPanel(
                         plotOutput("colloPlot", width = "100%", height = "680px")
                         )
                     )
                 ),
        tabPanel(title = "詞向量", icon = icon("location-arrow"),
                 # Input
                 sidebarLayout(
                     sidebarPanel(
                        HTML("<h3>歷時語意軌跡</h3>"),
                        textInput(
                             inputId = "keyterms", 
                             label = "詞彙：", 
                             value = "美國, 臺灣"
                         ),
                        sliderInput(
                           inputId = "timesteps",
                           label = "時間：",
                           min = min(timesteps),
                           max = max(timesteps),
                           value = c(6, 8),
                           step = 1, round = T
                        ),
                        HTML("<label>區間</label>"),
                        uiOutput("selectedTimeStepStr"),
                        
                        HTML("<h3>近似詞</h3>"),
                        selectInput(
                          inputId = "timestepsMostSimil",
                          label = "時間：",
                          choices = timesteps,
                          selected = 7,
                          multiple = FALSE,
                          selectize = TRUE
                        ),
                        sliderInput(
                           inputId = "numMostSimil",
                           label = "Top n：",
                           min = 3,
                           max = 60,
                           value = 5,
                           step = 1, round = T
                        ),
                        uiOutput("mostSimilarWords"),
                     ), 
                     # Plot
                     mainPanel(plotOutput("word2vecPlot", width = "100%", height = "580px")))
                 ),
        tabPanel(title = "句法依存", icon = icon("tree"),
                 sidebarLayout(
                     sidebarPanel(
                        textInput(
                             inputId = "keytermDep", 
                             label = "詞彙 (只可輸入一個)：", 
                             value = "臺灣"
                         ),
                         sliderInput(
                           inputId = "timestepsDep",
                           label = "時間：",
                           min = min(timesteps),
                           max = max(timesteps),
                           value = c(6, 8),
                           step = 1, round = T
                           ),
                         HTML("<label>區間：</label>"),
                         uiOutput("selectedTimeStepStrDep")
                         ),
                     # Plot
                     mainPanel(
                         plotOutput("depPlot", width = "98%", height = "680px"),
                         )
                     )
                 ),
        tabPanel(title = "主題模型", icon = icon("palette"),
                 sidebarLayout(
                     sidebarPanel(
                        textInput(
                             inputId = "keytermTopic", 
                             label = "詞彙 (只可輸入一個，可用 Regex)：", 
                             value = "臺灣"
                         ),
                         HTML("<label>區間：</label>"),
                         uiOutput("selectedTimeStepStrTopic")
                         ),
                     # Plot
                     mainPanel(
                         plotOutput("topic1Plot", width = "100%", height = "400px"),
                         plotOutput("topic2Plot", width = "100%", height = "400px")
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
                 )
        
    ),
    HTML('<span class="src-link" title="原始碼">
            <a href="https://github.com/rlads2021/TA-project" target="_blank" style="color:black">
                <i class="fab fa-github"></i>
            </a>
          </span>')
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    #### Word embedding ####
    output$word2vecPlot <- renderPlot({
        words <- strsplit(input$keyterms, ",")[[1]]
        rng <- input$timesteps
        timesteps
        embed_viz(
            search_terms = trimws(words),
            timesteps = seq(rng[1], rng[2], by = 1)
        )
    })
    output$selectedTimeStepStr <- renderUI({
        rng <- input$timesteps
        rng <- seq(rng[1], rng[2], by = 1)
        tags$ul(timesteps_li[rng], class = "timesteps")
    })
    output$mostSimilarWords <- renderUI({
        time = input$timestepsMostSimil
        topn = input$numMostSimil
        words <- strsplit(input$keyterms, ",")[[1]] %>% trimws()
        simil <- most_simil_multiple(words, time, topn = topn)
        
        out_html <- vector("character", length(simil))
        for (i in seq_along(simil)) {
           nm <- strsplit(names(simil)[i], "_")[[1]]
           word <- nm[1]
           src <- nm[2]
           
           simil_words <- simil[[i]]
           simil_words <- paste0(
              '<span class="word">',
              '<span class="form">', names(simil_words), '</span>',
              '<span class="similarity">', round(simil_words, 2), '</span>',
              '</span>'
           )
           simil_words <- paste0(
              "<div class='", src, "'>", 
                  "<span class='seed'>", word, "</span>",
                  "<div class='simil_words'>", 
                     paste(simil_words, collapse = ""), 
                  "</div>",
              "</div>"
            )
           out_html[i] <- simil_words
        }
        out_html = paste(out_html, collapse = "\n")
        tags$div(HTML(out_html), class = "most-similar-words-by-src")
    })
    
    #### Topic Modeling ####
    output$topic1Plot <- renderPlot({
      word <- input$keytermTopic
      
      patched <- list(
        topic_viz(trimws(word), "ptt"),
        topic_viz2(trimws(word), "ptt")
      )
      wrap_plots(patched)
    })
    output$topic2Plot <- renderPlot({
      word <- input$keytermTopic
      
      patched <- list(
        topic_viz(trimws(word), "wei"),
        topic_viz2(trimws(word), "wei")
      )
      wrap_plots(patched)
    })
    output$selectedTimeStepStrTopic <- renderUI({
        tags$ul(timesteps_li, class = "timesteps")
    })
    
    #### Dependency parsing ####
    output$depPlot <- renderPlot({
       rng <- input$timestepsDep
       rng <- seq(rng[1], rng[2], by = 1)
       dependency_viz(word = trimws(input$keytermDep), 
                      timesteps = rng)
    })
    output$selectedTimeStepStrDep <- renderUI({
       rng <- input$timestepsDep
       rng <- seq(rng[1], rng[2], by = 1)
        tags$ul(timesteps_li[rng], 
                class = "timesteps")
    })
    
    #### LSA ####
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
    
    #### Word Frequency ####
    output$wordfreqPlot <- renderPlot({
        words <- strsplit(input$wordfreq_selected_words, ",")[[1]]
        freq_viz(words = trimws(words))
    })
    output$selectedTimeStepStrWordfreq <- renderUI({
       tags$ul(timesteps_li, class = "timesteps")
    })
    
    #### Collocation ####
    output$colloPlot <- renderPlot({
       word <- trimws(input$keytermCollo)
       rng <- input$timestepsCollo
       rng <- seq(rng[1], rng[2], by = 1)
       colloc_viz(word = word, timesteps = rng, n = input$numOfCollo)
    })
    output$selectedTimeStepStrCollo <- renderUI({
       rng <- input$timestepsCollo
       rng <- seq(rng[1], rng[2], by = 1)
       tags$ul(timesteps_li[rng], class = "timesteps")
    })

}

# Run the application
shinyApp(ui = ui, server = server)
