shiny::runApp("shiny_doi/app.R")


rsconnect::deployApp(appDir = 'shiny_doi',
                     account = "benjamin-merkel")

 
# Register for the Polite Pool
# 
# If you are intending to access Crossref regularly you will want to send your 
# email address with your queries. This has the advantage that queries are placed 
# in the polite pool of servers. Including your email address is good practice as described 
# in the Crossref documentation under Good manners (https://github.com/CrossRef/rest-api-doc#good-manners--more-reliable-service). 
#  The second advantage is that Crossref can contact you if there is a problem with a query.
# 
# Details on how to register your email in a call can be found at ?rcrossref-package. To pass your email address to Crossref, simply store it as an environment variable in .Renviron like this:
#   
#   Open file: file.edit("~/.Renviron")
# 
# Add email address to be shared with Crossref crossref_email= "name@example.com"
# 
# Save the file and restart your R session
# 
# To stop sharing your email when using rcrossref simply delete it from your .Renviron file. 