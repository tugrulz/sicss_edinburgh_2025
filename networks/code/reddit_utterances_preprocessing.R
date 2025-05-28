

library(tidyverse)
library(rjson)

null_to_na <- function(x){
  null.elements <- unlist(lapply(x, is.null))
  x[null.elements] <- NA
  unlist(x)
}

# data from convokit python module
# https://convokit.cornell.edu/documentation/reddit-small.html

file.stem <- paste0("C:/Users/",
                    Sys.info()["user"],
                    "/OneDrive - University of Edinburgh/")

setwd(paste0(file.stem,"research/networks_sicss"))

utt <- fromJSON(file = "data/utterances.json")
meta <- lapply(utt, '[[', "meta")
subreddit <- unlist(lapply(meta, '[[', "subreddit"))

askreddit <- utt[which(subreddit=="AskReddit")]
askreddit2 <- data.frame(id = unlist(lapply(askreddit, '[[', "id")),
                         user = unlist(lapply(askreddit, '[[', "user")),
                         reply_to = null_to_na(lapply(askreddit, '[[', "reply_to")),
                         timestamp = unlist(lapply(askreddit, '[[', "timestamp")))

replies <- askreddit2 %>%
  filter(!is.na(reply_to)) %>%
  filter(user != "[deleted]") %>%
  filter(reply_to!="[deleted]") %>%
  select(-c(timestamp, reply_to))
  

el <- askreddit2 %>%
  left_join(replies,
            by = c("reply_to" = "id")) %>%
  rename(user_response = user.x, user_op = user.y) %>%
  drop_na(reply_to) %>%
  drop_na(user_op) 

write.csv(el, "data/askreddit_replies_edgelist.csv", row.names = F)




            



