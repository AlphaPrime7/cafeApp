library(shiny)
library(shinythemes)
library(bslib)
library(httr)
library(jsonlite)

ui <- fluidPage(
  shinythemes::themeSelector(),
  
  titlePanel(
    title = div(style = "text-align: center;",
                div("NBAPals", style = "font-size: 40px;"),
                div("NBA Data Analyzer", style = "font-size: 26px;")
    ),
    windowTitle = NULL
  ),
  
  fluidRow(
    column(12, align = "center",
           passwordInput("api_key", "Enter your RapidAPI Key:", ""),
    )
  ),
  
  fluidRow(
    column(12, align = "center",
           actionButton("toggle", "View or Hide Architecture")
    )
  ),
  
  fluidRow(
    column(12, align = "center", 
           tags$figure(
             class = "centerFigure",
             tags$img(
               src = "archi-nba.jpg",
               width = 750,
               alt = "NBA-API architecture found on Rapid API"
             ),
             tags$figcaption("NBA-API ARCHITECTURE")
           )),
  
)
)

server <- function(input, output, session) {
  output$download_code <- downloadHandler(
    filename = function() {
      file_ext <- switch(input$output_language,
                         "R" = ".R",
                         "Python" = ".py",
                         "Scala" = ".scala", 
                         "Ruby" = ".rb",
                         "JavaScript" = ".js",
                         "Java" = ".java",
                         "Ruby" = ".rb",
                         "Assembly Language" = ".asm",
                         "C++" = ".cpp",
                         "C#" = ".cs",
                         "C" = ".c",
                         "Go" = ".go",
                         "PHP" = ".php", 
                         "Matlab" = ".m", 
                         "TypeScript" = ".ts", 
                         "TSX" = ".tsx", 
                         "SAS"= ".sas",
                         "Perl" = ".pl",
                         "Julia" = ".jl")
      paste0("translated_code", file_ext)
    },
    content = function(file) {
      writeLines(input$output_code, file)
    },
    contentType = "text/plain"
  )
  
  observeEvent(input$upload_code, {
    req(input$upload_code)
    code <- readLines(input$upload_code$datapath)
    updateTextAreaInput(session, "input_code", value = paste(code, collapse = "\n"))
  })
  
  observeEvent(input$translate, {
    req(input$api_key, input$input_code)
    
    if (input$input_language == "Auto Detect") {
      messages <- list(list(role = "system"
                            , content = paste("Detect the programming language of the following code snippet:"
                                              , input$input_code)))
      detected_language_response <- openai_chat_completions(input$api_key, messages)
      detected_language <- detected_language_response$choices$message$content
      
      invisible(cat("Detected ", detected_language, "\n"))
      
    } else {
      detected_language <- input$input_language
    }
    
    # messages <- list(list(role = "system"
    #                       , content = paste("Translate the following"
    #                                         , detected_language, "code to"
    #                                         , input$output_language
    #                                         , "code, just give me the code with no comments:"
    #                                         , input$input_code)))
    
    messages <- list(list(role = "system"
                          #                     , content = paste("You are an expert programmer in all programming languages. Translate the "
                          #                                       , detected_language
                          #                                       , " code to "
                          #                                       , input$output_language
                          #                                       , " code. Do not include \`\`\`.
                          # 
                          # Example translating from JavaScript to Python:
                          # 
                          # JavaScript code:
                          # for (let i = 0; i < 10; i++) {
                          #   console.log(i);
                          # }
                          # 
                          # Python code:
                          # for i in range(10):
                          #   print(i)",
                          # 
                          #                                       detected_language, "code:",
                          #                                       input$input_code,
                          #                                       input$output_language, "code (no \`\`\`):")
                          , content = create_prompt(input_language = detected_language
                                                    , output_language = input$output_language
                                                    , input_code = input$input_code)
    ))
    
    model <- ifelse(input$model == "GPT-3.5", "gpt-3.5-turbo", "gpt-4")
    
    translation_response <- openai_chat_completions(input$api_key
                                                    , messages
                                                    , model = model
                                                    , temperature = 0
    )
    
    if (!is.null(translation_response)) {
      translated_code <- translation_response$choices$message$content
      updateTextAreaInput(session, "output_code", value = translated_code)
    } else {
      updateTextAreaInput(session, "output_code", value = "Translation failed. Please check your API key and input.")
    }
  })
  
  # Add new observer for clearing textbox areas when the user selects a new language
  observeEvent(input$input_language, {
    updateTextAreaInput(session, "input_code", value = "")
  })
  
  observeEvent(c(input$input_language, input$output_language), {
    updateTextAreaInput(session, "output_code", value = "")
  })
  
  # to make the code boxes dynamic  
  # observe({
  #   input$input_code
  #   runjs(sprintf("resizeTextarea('input_code');"))
  # })
  # 
  # observe({
  #   input$output_code
  #   runjs(sprintf("resizeTextarea('output_code');"))
  # })
}

shinyApp(ui = ui, server=server)