library(shiny)
library(rcrossref)
library(dplyr)
library(DT)
library(shinyjs) 
library(stringr)

# Function to get citation data and format it
get_citation_data <- function(dois, highlighted_authors) {
  citation_data <- lapply(dois, function(doi) {
    # Use rcrossref to get the citation data
    cr_data <- rcrossref::cr_works(doi)
    
    if (is.null(cr_data$data)) {
      return(NULL)  # Return NULL if no data is found
    }
    
    # Extract necessary details
    authors <- cr_data$data$author
    given <- authors[[1]]$given
    given <- str_split_fixed(given," ",2)
    
    given_initials <- c()
    for(g in 1:nrow(given)){
      given_initials <- c(given_initials, gsub("..",".",paste0(substr(given[g,], 1, 1), ".", collapse = ""), fixed = T))
    }
    authors[[1]]$given <- given_initials
    
    
    # Create a vector to hold formatted author names
    formatted_authors <- c()
    
    for (i in 1:nrow(data.frame(authors))) {
      author <- data.frame(authors)[i,]
      if (!is.null(author$family) && !is.null(author$given)) {
        # Check if the author's last name should be highlighted
        if (author$family %in% highlighted_authors) {
          formatted_authors <- c(formatted_authors, paste0("<b>", author$family, ", ", author$given, "</b>"))
        } else {
          formatted_authors <- c(formatted_authors, paste(author$family, author$given, sep = ", "))
        }
      }
    }
    
    # Collapse authors into a single string
    authors_string <- paste(formatted_authors, collapse = ", ")
    
    title <- cr_data$data$title[1]
    # Replace text in brackets with italicized text
    title <- gsub("\\(([^)]+)\\)", "<i>(\\1)</i>", title)
    
    year <- substr(cr_data$data$created,1,4)[1]
    journal <- cr_data$data$`container.title`[1]
    volume <- cr_data$data$volume
    doi_link <- paste0("DOI: ", doi)
    
    # Create formatted citation
    citation <- paste0(authors_string, " (", year, ") ", title, ". ", journal, ", ", volume, ". ", doi_link)
    # return(citation)
    return(list(citation = citation, first_author = authors[[1]]$family[1], year = year))
    
  })
  
  # Filter out NULL entries
  citation_data <- Filter(Negate(is.null), citation_data)
  
  # Convert list of lists to a single data frame
  citation_df <- bind_rows(lapply(citation_data, as.data.frame))
  
  return(citation_df)
}

# Define UI for the application
ui <- fluidPage(
  titlePanel("DOI Citation Fetcher"),
  sidebarLayout(
    sidebarPanel(
      textAreaInput("dois", "Enter DOIs (one per line):", value = "10.1007/s00300-023-03196-8\n10.3354/meps13673", height = "200px"),
      textAreaInput("highlighted_authors", "Enter Author Last Names to Highlight (comma-separated):", value = "Bengtsson, Lydersen, Strøm", height = "100px"),
      selectInput("sort_by", "Sort By:", choices = list("author - year" = "first_author", "year - author" = "year")),
      actionButton("submit", "Get Citation Data", class = "btn-primary btn-lg"),
      p("  "),
      p("by Benjamin Merkel, benjamin.merkel@npolar.no", style = "font-size:11px"),
      p("last updated 2024-11-05", style = "font-size:11px")
    ),
    mainPanel(
      uiOutput("citationOutput")
    )
  )
)

# Server function
server <- function(input, output) {
  citation_data <- reactiveVal()  # Store citation data reactively
  
  observeEvent(input$submit, {
    dois <- unlist(strsplit(trimws(input$dois), "\n"))  # Split DOIs by new lines
    highlighted_authors <- unlist(strsplit(trimws(input$highlighted_authors), ","))  # Split highlighted authors by commas
    highlighted_authors <- trimws(highlighted_authors)  # Trim whitespace
    
    citation_df <- get_citation_data(dois, highlighted_authors)  # Get and store citation data
    citation_data(citation_df)  # Update reactive value with new citation data
  })
  
  # Reactively update citations whenever sorting option changes
  sorted_citations <- reactive({
    req(citation_data())  # Ensure citation data is available
    citation_data() %>%
      arrange(first_author) %>%
      pull(citation)
  })
  
  sorted_citations <- reactive({
    req(citation_data())  # Ensure citation data is available
    citation_data() %>%
      arrange(year) %>%
      pull(citation)
  })
  
  sorted_citations <- reactive({
    req(citation_data())  # Ensure citation data is available
    citation_data() %>%
      arrange(if (input$sort_by == "year") year else first_author) %>%
      pull(citation)
  })
  
  # Render sorted citations
  output$citationOutput <- renderUI({
    if (is.null(citation_data()) || nrow(citation_data()) == 0) {
      return(h3("Run query")) # No citation data found for the entered DOIs.
    }
    
    # Create output with formatted citations
    citation_tags <- lapply(sorted_citations(), function(citation) {
      tags$p(HTML(citation))  # Use HTML to render bold text for highlighted authors
    })
    
    # Add a title to the citations
    output_title <- tags$h3("Citation Results:")
    
    # Combine the title and all citation elements into a tag list
    tagList(output_title, citation_tags)  
  })
}

# Run the application
shinyApp(ui = ui, server = server)
