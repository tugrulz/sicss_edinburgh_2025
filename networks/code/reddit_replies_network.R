
library(tidyverse)
library(igraph)


file.stem <- paste0("C:/Users/",
                    Sys.info()["user"],
                    "/OneDrive - University of Edinburgh/")

setwd(paste0(file.stem,"research/networks_sicss"))

# data from convokit python module
# https://convokit.cornell.edu/documentation/reddit-small.html
# see reddit_utterances_preprocessing.R

el <- read.csv("data/askreddit_replies_edgelist.csv")

ig <- graph_from_edgelist(as.matrix(el[,c("user_response", "user_op")]))

plot(ig,
     vertex.size =2,
     vertex.label = NA,
     edge.arrow.size = 0)

plot(ig,
     vertex.size =sqrt(degree(ig)+1),
     vertex.label = NA,
     edge.arrow.size = 0)

sort(degree(ig, mode = "in"), decreasing = T)[1:10]
sort(degree(ig, mode = "out"), decreasing = T)[1:10]
