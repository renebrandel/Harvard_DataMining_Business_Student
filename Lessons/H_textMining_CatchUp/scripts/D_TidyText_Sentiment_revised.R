#' Title: Intro: TidyText Sentiment
#' Purpose: Sentiment nonsense
#' Author: Ted Kwartler
#' email: edwardkwartler@fas.harvard.edu
#' License: GPL>=3
#' Date: Nov 16 2020
#'

# Set the working directory
setwd("~/Desktop/Harvard_DataMining_Business_Student/Lessons/H_textMining_CatchUp/data")


# Libs
library(tidytext)
library(dplyr)
library(qdap)
library(tm)
library(radarchart)
library(textdata)
library(ggplot2)

# Options & Functions
options(stringsAsFactors = FALSE)

# Custom Functions
tryTolower <- function(x){
  y = NA
  try_error = tryCatch(tolower(x), error = function(e) e)
  if (!inherits(try_error, 'error'))
    y = tolower(x)
  return(y)
}

cleanCorpus<-function(corpus,customStopwords){
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, stripWhitespace)
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus, content_transformer(tryTolower))
  corpus <- tm_map(corpus, removeWords, customStopwords)
  return(corpus)
}


# Data
text <- c(readLines('starboy.txt'), 
          readLines('in_your_eyes.txt'),
          readLines('pharrell_williams_happy.txt'))
cat(text)

docNames <- c("starboy", "eyes", "happy") 

# Create custom stop words
customStopwords <- c(stopwords('english'))

# Clean Corpus
txtCorpus <- VCorpus(VectorSource(text))
txtCorpus <- cleanCorpus(txtCorpus, customStopwords)

# DTM
txtDTM    <- DocumentTermMatrix(txtCorpus)
txtDTM
dim(txtDTM)

# Tidy
tidyCorp <- tidy(txtDTM)
tidyCorp
dim(tidyCorp)

# Get bing lexicon
# "afinn", "bing", "nrc", "loughran"
bing <- get_sentiments(lexicon = c("bing"))
head(bing)

# Perform Inner Join
bingSent <- inner_join(tidyCorp,bing, by=c('term'='word'))
bingSent

# Quick Analysis - count of words
bingAgg <- aggregate(count~document+sentiment, bingSent, sum)
reshape2::dcast(bingAgg, document~sentiment)

# Compare with qdap::Polarity
polarity(text[1])
polarity(text[2])
polarity(text[3])

# Sometimes text and sentiment can be temporal
coffee <- read.csv('coffee.csv')
head(coffee$created) 
tail(coffee$created)
coffee <- coffee[order(coffee$X, decreasing = T),]

# Corp and Join
coffeeCorpus <- VCorpus(VectorSource(coffee$text))
coffeeCorpus <- cleanCorpus(coffeeCorpus, customStopwords)
coffeeCorpus <- DocumentTermMatrix(coffeeCorpus)
coffeeCorpus <- tidy(coffeeCorpus)

# Get the AFINN lexicon
afinn <- read.csv('~/Desktop/Harvard_DataMining_Business_Student/Lessons/H_textMining_CatchUp/data/AFINN/afinn.csv')
head(afinn)

# Join
coffeeAfinn <- inner_join(coffeeCorpus, afinn, by = c('term' = 'word'))
coffeeAfinnAgg <- aggregate(value ~ document, coffeeAfinn, sum)

# Quick timeline, but of course with timestamps you could make a real "time series" object
coffeeAfinnAgg$document <- as.numeric(as.character(coffeeAfinnAgg$document))
coffeeAfinnAgg <- coffeeAfinnAgg[order(coffeeAfinnAgg$document),]
plot(coffeeAfinnAgg$value, type = 'l')

# Get nrc lexicon, again causes probs on rstudio cloud
#nrc <- textdata::lexicon_nrc() # should download it
nrc <- read.csv('~/Desktop/Harvard_DataMining_Business_Student/Lessons/H_textMining_CatchUp/data/NRC/nrc.csv')
head(nrc)

# Perform Inner Join
nrcSent <- inner_join(tidyCorp,nrc, by=c('term' = 'word'))
nrcSent

# Drop pos/neg leaving only emotion
nrcSent <- nrcSent[-grep('positive|negative',nrcSent$sentiment),]

# Quick chk
table(nrcSent$sentiment,nrcSent$document)

# Manipulate for radarchart
nrcSentRadar <- as.data.frame.matrix(table(nrcSent$sentiment, nrcSent$document))
nrcSentRadar
colnames(nrcSentRadar) <- docNames

# Normalize for length; prop.table needs a "matrix" class...annoying!
nrcSentRadar <- prop.table(as.matrix(nrcSentRadar),2)
nrcSentRadar
colSums(nrcSentRadar)

# Organize
nrcSentRadar <- data.frame(labels = rownames(nrcSentRadar),
                           nrcSentRadar)
rownames(nrcSentRadar) <- NULL
nrcSentRadar

# Chart
chartJSRadar(scores = nrcSentRadar, labelSize = 10, showLegend = T)
# End