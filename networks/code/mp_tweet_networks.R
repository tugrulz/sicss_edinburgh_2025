
### load packages, define functions, set working directory ######

library(tidyverse)    # data management
library(ggplot2)      # plots
library(igraph)       # network analysis
library(RColorBrewer) # some functions for colors in in plots
library(classInt)     # classIntervals function - used in assigning colors
library(lubridate)    # some date functions
library(zoo)          # some more date functions
library(stringr)      # text processing

# function to extract main component from igraph object
main.component <- function(graph, ...) {
  cl <- clusters(graph, ...)
  induced.subgraph(graph, which(cl$membership == which.max(cl$csize)))
}

# mode function
Mode <- function(x) {
  ux <- unique(na.omit(x))
  ux[which.max(tabulate(match(x, ux)))]
}

# set an appropriate working directory for your system
# working directory should contain the subfolder "results"

file.stem <- paste0("C:/Users/",
                    Sys.info()["user"],
                    "/OneDrive - University of Edinburgh/")

setwd(paste0(file.stem,"research/networks_sicss/networks_sicss"))

### read and restructure MP tweet data ##########

tweets <- readRDS(gzcon(url("https://github.com/cjbarrie/CTA-ED/blob/main/data/wordembed/twts_corpus_sample.rds?raw=true")))%>%
  rename(retweet_username = reftweet_username) %>%
  mutate(year.month = format(date, "%Y-%m"),
         year.week = str_c(
                          formatC(isoweek(date), format = "f", digits = 0, width = 2, flag = "0"), 
                          "/", 
                          str_sub(isoyear(date), 3, 4)),
         year.quarter = ordered(paste(year(date), quarter(date), sep = "-")),
         username = tolower(username),
         retweet_username = tolower(retweet_username))

# if you want to save the data locally 
# write.csv(tweets, "data/UK parliament/MPtweets.csv") 

### explore the raw data

min(tweets$date) # date of the first tweet
max(tweets$date) # date of the last tweet

tweets %>%
  group_by(date) %>%
  summarise(n.tweets = n()) %>%
  ggplot(., aes(y = n.tweets, x = date ))+
    geom_line()+
    geom_vline(xintercept = as.Date("2019-05-24"), color = "blue")+
    annotate("text", x = as.Date("2019-05-24"), y = 300, label = "PM Teresa May resigns", hjust = 1.1, color = "blue")+
    geom_vline(xintercept = as.Date("2019-12-12"), color = "blue")+
    annotate("text", x = as.Date("2019-12-12"), y = 300, label = "General Election", hjust = 1.1, color = "blue")

length(unique(tweets$username)) # number of tweeting accounts in dataset (note that there are 650 MPs)
length(unique(tweets$retweet_username)) # number of retweeted accounts

# table of party frequency
tweets %>%
  group_by(username) %>%
  summarise(party = unique(party_value)) %>%
  group_by(party) %>%
  summarise(n = n()) %>%
  ungroup() %>%
  mutate(fraction = n/sum(n))


### sample of tweets between T. May's resignation and the 2019 general election ####################

# create an edgelist
rt.samp1 <- tweets %>%
  filter(date > as.Date("2019-05-24"))%>%           # select tweets after 25 May 2019 (note that the election date is the end of the data collected)
  drop_na(retweet_username) %>%                     # drop tweets that are not retweets
  group_by(retweet_username, username) %>%          # our unit of analysis is the dyad (username - retweet username pair)
  summarise(n_retweets = n()) %>%                   # count of the number of times i retweets j
  relocate(retweet_username, username,n_retweets)   # reorder columns

# convert data to an igraph object
# IMPORTANT: note that the order of columns below embeds a key assumption that affects interpretation
# here we treat a tie as going FROM retweet_username TO username
rt.samp1.ig <- graph_from_edgelist(                       # create igraph object
  as.matrix(rt.samp1[,c("retweet_username","username")]), # igraph demands a two-column matrix
  directed = T                                            # our data are directed
)
rt.samp1.ig$weight <- rt.samp1$n_retweets                 # AFAIK we have to add any weights after creating the object


# now create attribute data: legislator party id

party.id <- tweets %>%       # create a data frame with the party id of each MP
  group_by(username) %>%
  summarise(party = unique(party_value)) %>%
  mutate(party.color = recode(party,                      # I assign standard party colors using hex codes
                              "Conservative" = "#0087DC",
                              "Democratic Unionist Party" = "#D46A4C",
                              "Green Party" = "#528D6B",
                              "Labour" = "#E4003B",
                              "Labour (Co-op)" = "#E4003B",
                              "Liberal Democrat" = "#FDBB30",
                              "Plaid Cymru" = "#005B54",
                              "Scottish National Party" = "#FFFF00")
  )

# first, note that the V() function returns vertex attributes from an igraph object
V(rt.samp1.ig)
# we can index with $. in general there will be a vertex attribute "name" that was assigned when igraph created the object
V(rt.samp1.ig)$name

rt.samp1.attr <- data.frame(username = V(rt.samp1.ig)$name) %>% # retrieve the usernames from our network
  mutate(node.sequence = row_number()) %>%                        # I create a numerical id to keep track of node order
  left_join(party.id, by = "username")



### visualise the network! ###########################

plot(rt.samp1.ig)      # first, note that the igraph default plot is not very helpful

pdf("results/rt-samp1.pdf", width = 12)   # I like to save plots as pdf, which has high resolution
plot(simplify(rt.samp1.ig), # simplify removes loops
     vertex.label = NA, # ignore vertex labels
     vertex.size = 4,   # set node size
     vertex.color = NA,
     edge.arrow.size = 0) # remove arrows
dev.off()

# add party labels
pdf("results/rt-samp1-partylab.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = rt.samp1.attr$party.color,
     edge.arrow.size = 0)
dev.off()


### explore centrality scores ############################
# who are the most central nodes?
# what is the shape of the degree distribution?
# how does in degree vary by party (e.g. are members of any party more central?)
# how could we add other centrality measures, e.g. betweenness?
# how can we create a summary dataset using dplyr?

sort(degree(rt.samp1.ig, mode = "out"), decreasing = T)[1:10] # the top 10 users with most retweet parters (NOT count of retweets)
sort(degree(rt.samp1.ig, mode = "in"), decreasing = T)[1:10]  # the top 10 users who retweet the most other accounts
sort(degree(rt.samp1.ig, mode = "all"), decreasing = T)[1:10] # top 10 accounts with most retweet conenctions overall

# relationship between in degree and out degree
plot(degree(rt.samp1.ig, mode = "in"), degree(rt.samp1.ig, mode = "out"))

# plot degree distribution
data.frame(degree.in = degree(rt.samp1.ig, mode = "in")) %>%
  ggplot(., aes(x = degree.in))+
    geom_histogram()+
    scale_y_continuous(trans = 'log1p')


# eigenvector centrality and variations

sort(eigen_centrality(rt.samp1.ig)$vector, decreasing = T)[1:10] # 10 nodes with highest eigenvector centrality
sort(page_rank(rt.samp1.ig)$vector, decreasing = T)[1:10]        # 10 nodes with highest pagerank centrality

plot(eigen_centrality(rt.samp1.ig)$vector, page_rank(rt.samp1.ig)$vector)

### plots with node size scaled to centrality

pdf("results/rt-samp1-partylab-outdegree.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     vertex.label = ifelse(degree(rt.samp1.ig, mode = "out")>=39, rt.samp1.attr$username, NA), 
     vertex.label.color = "chartreuse",
     vertex.size = log1p(degree(rt.samp1.ig, mode = "out")*10),
     vertex.color = rt.samp1.attr$party.color,
     edge.arrow.size = 0)
dev.off()

pdf("results/rt-samp1-partylab-pagerank.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     vertex.label = ifelse(page_rank(rt.samp1.ig)$vector>=.01, rt.samp1.attr$username, NA), 
     vertex.label.color = "chartreuse",
     vertex.size = log1p(page_rank(rt.samp1.ig)$vector*100),
     vertex.color = rt.samp1.attr$party.color,
     edge.arrow.size = 0)
dev.off()


# we might want to know -- are MPs from some parties more central than others?

# compile centrality scores into a data frame with party
rt.samp1.centrality <- data.frame(
  username = V(rt.samp1.ig)$name,
  degree.in = degree(rt.samp1.ig, mode = "in"),
  degree.out = degree(rt.samp1.ig, mode = "out"),
  eigen.centrality = eigen_centrality(rt.samp1.ig)$vector,
  page.rank = page_rank(rt.samp1.ig)$vector
  ) %>%
  mutate(node.sequence = row_number()) %>%
  left_join(party.id,
            by = "username")


ggplot(filter(rt.samp1.centrality, !is.na(party)),
       aes(x = degree.in, color = party))+
  geom_density()+
  scale_y_continuous(trans = 'log1p')+
  scale_color_manual(values = c("Conservative" = "#0087DC",
                       "Democratic Unionist Party" = "#D46A4C",
                       "Green Party" = "#528D6B",
                       "Labour" = "#E4003B",
                       "Labour (Co-op)" = "#E4003B",
                       "Liberal Democrat" = "#FDBB30",
                       "Plaid Cymru" = "#005B54",
                       "Scottish National Party" = "#FFFF00"))+
  theme_bw()

rt.samp1.centrality %>%
  drop_na(party) %>%
  group_by(party) %>%
  summarise(degree.in.mean = mean(degree.in),
            degree.in.median = median(degree.in),
            pagerank.mean = mean(page.rank),
            ragerank.median = median(page.rank))



### detect subgroups/communities #########################
# we'll try four common community detection methods
# most community detection methods are designed for undirected networks
# we also simplify to remove self-ties (self-retweets)
# which method seems to perform best?

# Clauset, Aaron, M. E. J. Newman, and Cristopher Moore. 2004. “Finding Community Structure in Very Large Networks.” Physical Review E 70(6):066111. doi: 10.1103/PhysRevE.70.066111.
rt.samp1.greedy <- cluster_fast_greedy(as.undirected(simplify(rt.samp1.ig)))

# Blondel, Vincent D., Jean-Loup Guillaume, Renaud Lambiotte, and Etienne Lefebvre. 2008. “Fast Unfolding of Communities in Large Networks.” Journal of Statistical Mechanics: Theory and Experiment 2008(10):P10008. doi: 10.1088/1742-5468/2008/10/P10008.
rt.samp1.louvain <- cluster_louvain(as.undirected(simplify(rt.samp1.ig)))

# Traag, V. A., L. Waltman, and N. J. van Eck. 2019. “From Louvain to Leiden: Guaranteeing Well-Connected Communities.” Scientific Reports 9(1):5233. doi: 10.1038/s41598-019-41695-z.
rt.samp1.leiden <- cluster_leiden(as.undirected(simplify(rt.samp1.ig)),
                              objective_function = "modularity",
                              # set initial values to party, or 99 if unobserverved
                              initial_membership = ifelse(!is.na(rt.samp1.attr$party),
                                               as.numeric(as.factor(rt.samp1.attr$party)),
                                               99),
                              resolution_parameter = .5)

# Raghavan, Usha Nandini, Réka Albert, and Soundar Kumara. 2007. “Near Linear Time Algorithm to Detect Community Structures in Large-Scale Networks.” Physical Review E 76(3):036106. doi: 10.1103/PhysRevE.76.036106.
rt.samp1.labelprop <- cluster_label_prop(as.undirected(simplify(rt.samp1.ig)),
                                     # set initial values to party, or -1 if unobserverved
                                     initial = ifelse(!is.na(rt.samp1.attr$party),
                                                      as.numeric(as.factor(rt.samp1.attr$party)),
                                                      -1),
                                     # fix labels for nodes with observed party
                                     fixed = !is.na(rt.samp1.attr$party))


# compare the number and size distribution of groups
table(rt.samp1.greedy$membership)
table(rt.samp1.louvain$membership)
table(rt.samp1.leiden$membership)
table(rt.samp1.labelprop$membership)

# compare modularity scores
modularity(rt.samp1.greedy)
modularity(rt.samp1.louvain)
modularity(rt.samp1.ig, rt.samp1.leiden$membership)
modularity(rt.samp1.labelprop)



pdf("results/rt-samp1-greedylab.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     #layout = l,
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = rt.samp1.greedy$membership,
     edge.arrow.size = 0)
dev.off()

pdf("results/rt-samp1-louvainlab.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     #layout = l,
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = rt.samp1.louvain$membership,
     edge.arrow.size = 0)
dev.off()

pdf("results/rt-samp1-leidenlab.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     #layout = l,
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = rt.samp1.leiden$membership,
     edge.arrow.size = 0)
dev.off()

pdf("results/rt-samp1-labelprop.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     #layout = l,
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = rt.samp1.labelprop$membership,
     edge.arrow.size = 0)
dev.off()



# within each subgroup, what % of nodes belong to each party?
# (among accounts that belong to MPs?)


rt.samp1.subgroups <- data.frame(
  username = V(rt.samp1.ig)$name,
  subgroup.leiden = rt.samp1.leiden$membership,
  subgroup.labelprop = rt.samp1.labelprop$membership) %>%
  left_join(rt.samp1.attr, by = "username") %>%
  group_by(subgroup.leiden) %>%
  mutate(n.labour = sum(party=="Labour" | party=="Labour (Co-op)", na.rm = T),
          leiden.pcnt.labour = 
           sum(party=="Labour" | party=="Labour (Co-op)", na.rm = T)/sum(!is.na(party)),
         leiden.pcnt.cons = 
           sum(party=="Conservative", na.rm = T)/sum(!is.na(party)),
         leiden.lean.cons = leiden.pcnt.cons- leiden.pcnt.labour) %>%
  # assign a party to each community defined by label propagation
  # based on the modal observed party in each group
  group_by(subgroup.labelprop) %>%
  mutate(labelprop.party.mode = Mode(party),
         labelprop.party.color = recode(labelprop.party.mode,
                              "Conservative" = "#0087DC",
                              "Democratic Unionist Party" = "#D46A4C",
                              "Green Party" = "#528D6B",
                              "Labour" = "#E4003B",
                              "Labour (Co-op)" = "#E4003B",
                              "Liberal Democrat" = "#FDBB30",
                              "Plaid Cymru" = "#005B54",
                              "Scottish National Party" = "#FFFF00")
  )
  

# assign colors to subgroups

nclr <- 10
min <- -1 # theoretical minimum
max <- 1 # theoretical maximum
breaks <- (max - min) / nclr

plotclr <- brewer.pal(nclr, "RdBu")
plotvar <- rt.samp1.subgroups$leiden.lean.cons
class <- classIntervals(plotvar,
                        nclr,
                        style = "fixed",
                        fixedBreaks = seq(min, max, breaks))
colcode <- findColours(class, 
                       plotclr)

pdf("results/rt-samp1-leiden-leancons.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = colcode,
     edge.arrow.size = 0)
dev.off()

pdf("results/rt-samp1-labelprop-party.pdf", width = 12)
plot(simplify(rt.samp1.ig), 
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = rt.samp1.subgroups$labelprop.party.color,
     edge.arrow.size = 0)
dev.off()


# having gotten this far, should we describe the MP retweet as 'polarized' or not?

### mention networks: one period ###########################


mentions <- tweets %>%
  filter(date > as.Date("2019-05-24")) %>% 
  filter(nchar(ments)>0) 

mentions.temp <- strsplit(mentions$ments, ",", fixed = T)

mentions.long <- data.frame(
  date = as.Date(unlist(mapply(rep,
                               as.list(mentions$date),
                               lapply(mentions.temp, length))),
                 format = "%Y-%m-%d",
                 origin = "1970-01-01"),
  username = unlist(mapply(rep,
                           as.list(mentions$username),
                           lapply(mentions.temp, length))),
  mentioned.account = trimws(unlist(mentions.temp)),
  stringsAsFactors = F
) %>%
  mutate(mentioned.account = gsub("@","",
                                  mentioned.account,
                                  fixed = T),
         #year.month = format(date, "%Y-%m")
         ) %>%
  filter(nchar(mentioned.account)>0) %>%
  group_by(username,mentioned.account) %>%
  summarize(n_mentions = n())



mentions.ig <- graph_from_edgelist(
            as.matrix(
                mentions.long[,c("username","mentioned.account")]
                )
            )

plot(simplify(mentions.ig), 
     vertex.label = NA, 
     vertex.size = 2,
     edge.arrow.size = 0)


mentions.samp.attr <- data.frame(
  username = V(mentions.ig)$name,
  node.seq = 1:length(V(mentions.ig)$name),
  degree.in = degree(mentions.ig, mode = "in")
  ) %>%
  left_join(party.id,
            by = "username")

pdf("results/mentions-samp-partylab.pdf", width = 12)
plot(simplify(mentions.ig), 
     vertex.label = NA, 
     vertex.size = 4,
     vertex.color = mentions.samp.attr$party.color,
     edge.arrow.size = 0)
dev.off()

# now try replicating analyses above with the mentions network


### Networks over time: construct monthly retweet networks #######

# select retweets, summarise over dyad-month
retweets.monthly <- tweets %>%
  drop_na(retweet_username) %>%
  group_by(retweet_username, username, year.month) %>%          # our unit of analysis is the dyad-month (username - retweet username pair in each month)
  summarise(n_retweets = n()) %>%                             # count of the number of times i retweets j
  relocate(retweet_username, username,n_retweets)

# split the data by month, creating list, and format as matrix
el.rt.monthly <- lapply(split(retweets.monthly, retweets.monthly$year.month), 
                      function(x){
  as.matrix(x[,c("retweet_username","username")])
})

# create list of of igraph objects
ig.rt.monthly <- lapply(el.rt.monthly,
                        graph_from_edgelist, 
                        directed = T)


# gather node-level information
# in this case we will just use a loop for convenience
# note that we pre-assign the list nodes.monthly
# as before it is important to keep track of the NODE ORDER


nodes.monthly <- list()
for(i in 1:length(ig.rt.monthly)){
  nodes.monthly[[i]] <-  data.frame(username = V(ig.rt.monthly[[i]])$name)
  nodes.monthly[[i]]$node.seq <- 1:nrow(nodes.monthly[[i]])
  nodes.monthly[[i]] <- merge(nodes.monthly[[i]],
                              party.id,
                              by = "username",
                              all.x = T)
  nodes.monthly[[i]]$party.color <- ifelse(is.na(nodes.monthly[[i]]$party.color),
                                           NA,
                                           nodes.monthly[[i]]$party.color)
  nodes.monthly[[i]] <- nodes.monthly[[i]][order(nodes.monthly[[i]]$node.seq),]
  # note that we can also assign vertex attributes to the igraph object
  V(ig.rt.monthly[[i]])$vertex.color <- nodes.monthly[[i]]$party.color
  
}

### visualize all the networks ########

dates <- unique(retweets.monthly$year.month)

for(i in 1:length(ig.rt.monthly)){
pdf(paste0("results/rt-monthly-", dates[i],".pdf"), width = 12)
  plot(simplify(ig.rt.monthly[[i]]), 
      vertex.label = NA, 
      vertex.size = 4,
      vertex.color = V(ig.rt.monthly[[i]])$vertex.color,
      edge.arrow.size = 0,
      main = dates[i])
  dev.off()
}  

### modularity analysis in monthly data ########

labelprop.fun <- function(graph, ...){
  cluster_label_prop(simplify(as.undirected(graph)))
}

### label propagation monthly

initial.list <- lapply(nodes.monthly, function(x){
  ifelse(!is.na(x$party),
         as.numeric(as.factor(x$party)),
         -1)
})

monthly.labelprop <- mapply(labelprop.fun,
                            graph = ig.rt.monthly,
                            initial = initial.list,
                            fixed = lapply(initial.list,
                                           function(x) !is.na(x)))


data.frame(
  date = as.Date(as.yearmon(names(lapply(monthly.labelprop, modularity)))),
  modularity = unlist(lapply(monthly.labelprop, modularity))
) %>%
  ggplot(., aes(y = modularity, x = date))+
    geom_line()



for(i in 1:length(ig.rt.monthly)){
  pdf(paste0("results/rt-monthly-labelprop-", dates[i],".pdf"), width = 12)
  plot(simplify(ig.rt.monthly[[i]]), 
       vertex.label = NA, 
       vertex.size = 5,
       vertex.color = monthly.labelprop[[i]]$membership,
       edge.arrow.size = 0,
       main = dates[i])
  dev.off()
} 

### Leiden algorithm monthly

leiden.fun <- function(graph,...){
  cluster_leiden(as.undirected(simplify(graph)),
                 objective_function = "modularity")
}

initial.list <- lapply(nodes.monthly, function(x){
  ifelse(!is.na(x$party),
         as.numeric(as.factor(x$party)),
         99)
})

monthly.leiden <- mapply(leiden.fun,
                         graph = ig.rt.monthly,
                         initial_membership = initial.list)


modul.monthly.leiden <- mapply(modularity,
                               x = ig.rt.monthly,
                               membership = lapply(monthly.leiden,
                                                   membership))

data.frame(
  date = as.Date(as.yearmon(names(lapply(monthly.labelprop, modularity)))),
  modul.labelprop = unlist(lapply(monthly.labelprop, modularity)),
  modul.leiden = unlist(modul.monthly.leiden)
  ) %>%
  pivot_longer(-date)%>%
  ggplot(., aes(y = value, x = date, color = name))+
  geom_line()+
  xlab("")+
  ylab("modularity")+
  scale_color_discrete(name = "Method", labels = c("Label propagation", 
                                                   "Leiden"))+
  theme_bw(base_size = 16)

ggsave("results/modularity-trend.pdf", width = 12, height = 10)


for(i in 1:length(ig.rt.monthly)){
  pdf(paste0("results/rt-monthly-leiden-", dates[i],".pdf"), width = 12)
  plot(simplify(ig.rt.monthly[[i]]), 
       vertex.label = NA, 
       vertex.size = 5,
       vertex.color = monthly.leiden[[i]]$membership,
       edge.arrow.size = 0,
       main = dates[i])
  dev.off()
} 

### centrality over time ######################

outdeg.monthly <- data.frame(
    index = names(unlist(lapply(ig.rt.monthly, degree, mode = "out"))),
    degree.out = unlist(lapply(ig.rt.monthly, degree, mode = "out"))
  ) %>%
  mutate(year.month = substring(index,1,7),
         username = substring(index,9,nchar(index))) %>%
  group_by(username) %>%
  mutate(ever.high.indeg = any(degree.out > 30)) %>%
  left_join(party.id, by = "username")

outdeg.monthly.party <- outdeg.monthly %>%
  drop_na(party) %>%
  group_by(party, year.month) %>%
  summarize(outdeg.party.mean = mean(degree.out),
            outdeg.party.median = median(degree.out),
            outdeg.party.sd = sd(degree.out))


ggplot(filter(outdeg.monthly, ever.high.indeg == T),
       aes(y = degree.out, x = year.month, group = username,
           color = username))+
  geom_line() + geom_smooth(se = F) +
  xlab("")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, 
                                   vjust = 0.5, hjust=1))
  

ggplot(outdeg.monthly.party, aes(y = outdeg.party.mean, 
                             x = year.month, 
                             group = party, color = party))+
  geom_line()+geom_smooth(se = F) +
  xlab("")+
  scale_color_manual(values = c("Conservative" = "#0087DC",
                                "Democratic Unionist Party" = "#D46A4C",
                                "Green Party" = "#528D6B",
                                "Labour" = "#E4003B",
                                "Labour (Co-op)" = "#E4003B",
                                "Liberal Democrat" = "#FDBB30",
                                "Plaid Cymru" = "#005B54",
                                "Scottish National Party" = "#FFFF00"))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, 
                                   vjust = 0.5, hjust=1))

ggplot(outdeg.monthly.party, aes(y = outdeg.party.median, 
                                x = year.month, 
                                group = party, color = party))+
  geom_line()+geom_smooth(se = F) +
  xlab("")+
  scale_color_manual(values = c("Conservative" = "#0087DC",
                                "Democratic Unionist Party" = "#D46A4C",
                                "Green Party" = "#528D6B",
                                "Labour" = "#E4003B",
                                "Labour (Co-op)" = "#E4003B",
                                "Liberal Democrat" = "#FDBB30",
                                "Plaid Cymru" = "#005B54",
                                "Scottish National Party" = "#FFFF00"))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, 
                                   vjust = 0.5, hjust=1))


ggplot(outdeg.monthly.party, aes(y = outdeg.party.sd, 
                                x = year.month, 
                                group = party, color = party))+
  geom_line()+geom_smooth(se = F) +
  xlab("")+
  scale_color_manual(values = c("Conservative" = "#0087DC",
                                "Democratic Unionist Party" = "#D46A4C",
                                "Green Party" = "#528D6B",
                                "Labour" = "#E4003B",
                                "Labour (Co-op)" = "#E4003B",
                                "Liberal Democrat" = "#FDBB30",
                                "Plaid Cymru" = "#005B54",
                                "Scottish National Party" = "#FFFF00"))+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, 
                                   vjust = 0.5, hjust=1))
                            
  



