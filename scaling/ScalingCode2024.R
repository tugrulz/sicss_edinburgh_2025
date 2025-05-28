# 0.1 Setting the Global Options #####
setwd("~/Library/CloudStorage/OneDrive-UniversityofEdinburgh/++Active/Teaching/Scaling/Scaling2023")

options(width=60,
        str=strOptions(strict.width="wrap"))


# 0.1 Loading Packages ######
pckgs <-
  c(
    "hbamr",
    "oc",
    "smacof",
    "tidyverse",
    "mirt",
    "ggthemes"
  )
lapply(pckgs, require, character.only = TRUE)


# 1. Hierarchical Bayesian Aldrich-McKelvey Scaling ----

data(LC1980)
LC1980[LC1980 == 0 | LC1980 == 8 | LC1980 == 9] <- NA 
head(LC1980)
self <- LC1980[, 1]
stimuli <- LC1980[, -1]

fit_hbam <- hbam(self, stimuli, warmup = 300, iter = 1000)

plot_stimuli(fit_hbam)

plot_respondents(fit_hbam)

# 2. Graded Item Response Modeling ----

# Load the data
load("~/Library/CloudStorage/OneDrive-UniversityofEdinburgh/++Active/Teaching/Scaling/Scaling2023/CDS2000.rda")

CDS2000 -> data;

# Select the relevant columns (columns 5 to 14) as specified
# Adjust column indices if the data has row or column headers that affect indexing
items <- data[, 5:14]

# Replace all occurrences of 99 with NA to treat them as missing values
items[items == 99] <- NA

# Check for missing values and handle them (e.g., by removing rows with missing data)
items <- na.omit(items)

# Fit the Graded Response Model
# The mirt() function fits a model for multidimensional IRT, but setting "model = 1" fits a unidimensional model for the graded responses. 
grm_model <- mirt(items, model = 1, itemtype = "graded")
 
# Summary of the model to see the discrimination and threshold parameters
summary(grm_model)

# Plot the Item Characteristic Curves (ICCs) for each item
# These curves show the probability of endorsing each response category as a function of the latent trait
plot(grm_model, type = "trace")

# Additional: Item Information Curves (IICs)
# These curves show how much information each item provides at different levels of the latent trait
plot(grm_model, type = "infotrace")

# Additional: Test Information Function (TIF)
# This curve shows the total information provided by the test at each level of the latent trait
plot(grm_model, type = "info")

# 3. Multidimensional Scaling (SMACOF - Scaling by Majorizing a Complicated Function) ----

# In 1968, Wish (1971) asked 18 students in his psychological measurement class to rate the perceived similarity between each pair of 12 nations using a 9-point scale ranging from "1=very different" to "9=very similar.He then constructed a matrix of average similarity ratings between the twelve nations.

# Load the dataset containing similarity ratings between pairs of nations
load("nations.rda")
print(nations) # Print the matrix to verify it is loaded correctly

# Transform the similarity ratings into distance values (lower distance = higher similarity)
# by subtracting each rating from 9 and then squaring the result
d <- (9 - nations)^2

# Perform metric Multidimensional Scaling (MDS) on the transformed distance matrix
smacof_metric_result <- smacofSym(delta=d, ndim=2, itmax=1000,
                                  type="interval", eps=0.000001)

# Extract the 2-dimensional configuration (coordinates) from the MDS result
conf <- smacof_metric_result$conf
print(smacof_metric_result$niter) # Print number of iterations for convergence
print(smacof_metric_result$stress) # Print stress value to evaluate model fit

# Prepare data for plotting the 2-dimensional MDS configuration
smacof.dat <- data.frame(
  dim1 = conf[,1],
  dim2 = conf[,2],
  country=rownames(nations)
)

# Plot the countries in the 2-dimensional MDS space
ggplot(smacof.dat, aes(x=dim1, y=dim2)) +
  geom_point() + # Plot points for each country
  geom_text(aes(label=country), nudge_y=-.05) + # Add country names near points
  xlab("") +
  ylab("") +
  xlim(-1,1) +
  ylim(-1,1) +
  theme_economist()  +
  theme(aspect.ratio=1) # Keep aspect ratio 1:1 for equal scaling on both axes

# Explore the relationship between dimensionality and stress
ndim <- 5
result <- vector("list", ndim)
for (i in 1:ndim) {
  # Run MDS for each dimension (1 through ndim) and store the result
  result[[i]] <- smacofSym(delta=d, ndim=i, type="interval")
}
# Extract stress values for each dimension to evaluate model fit
stress <- sapply(result, function(x) x$stress)

# Create a data frame pairing each dimension with its stress value
stress.df <- data.frame(
  stress=stress,
  dimension=1:length(stress)
)

# Plot stress values against dimensions to find the "elbow" point, indicating the optimal number of dimensions
ggplot(stress.df, aes(x=dimension, y=stress)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x="Dimension", y="Stress") # Label axes for clarity

# 4. Optimal Classification (OC) ----

# Load the dataset containing data on the French Fourth Republic's National Assembly roll call votes
load("~/Library/CloudStorage/OneDrive-UniversityofEdinburgh/++Active/Teaching/Scaling/Scaling2023/france4.rda")

# Create a rollcall object with voting data from france4
rc <- rollcall(data=france4[,6:ncol(france4)],
               yea=1,                    # Code for "yea" votes
               nay=6,                    # Code for "nay" votes
               missing=7,                # Code for missing votes
               notInLegis=c(8,9),        # Codes for non-legislative status
               legis.names=paste(france4$NAME, france4$CASEID, sep=""), # Legislator names
               vote.names=colnames(france4[6:ncol(france4)]),           # Vote names
               legis.data=france4[,2:5], # Additional data about legislators
               vote.data=NULL,           # No additional vote data
               desc="National Assembly of the French Fourth Republic")

# Perform Optimal Classification (OC) scaling in 2 dimensions
result2 <- oc(rc, dims=2, minvotes=20, lop=0.025,
              polarity=c(2,2), verbose=FALSE)
summary(result2) # Print a summary of the 2-dimensional OC model

# Perform Optimal Classification (OC) scaling in 1 dimension for comparison
result1 <- oc(rc, dims=1, minvotes=20, lop=0.025,
              polarity=2, verbose=FALSE)
summary(result1) # Print a summary of the 1-dimensional OC model

# Combine and label the fit statistics (e.g., % correct, APRE) for 1D and 2D models
fits <- cbind(result1$fits, result2$fits)
colnames(fits) <- c("1 Dim", "2 Dim")
rownames(fits) <- c("% Correct", "APRE")
fits # Display the fit statistics for both models

# Set the result to use the 2-dimensional OC model
result <- result2

# Recode party labels for plotting (e.g., "Communist", "Socialist")
pb <- rc$legis.data$PAR
pb <- car::recode(pb, '1="Communitst"; 2="Socialists";
     5="Christian Dems"; 7="Poujadists"; else=NA', as.factor=TRUE)

# Plot the 2-dimensional OC coordinates with labeled party groups
plot_oc_coords(result, pb, dropNV=TRUE, ptSize=3) +
  theme_bw() +
  theme(aspect.ratio=1, legend.position="bottom") +
  scale_shape_manual(values=c("C", "S", "D", "P"),
                     labels=c("Communist", "Socialist",
                              "Christian Dem", "Poujadists"),
                     name="Party") +
  scale_color_manual(values=gray.colors(5),
                     labels=c("Communist", "Socialist",
                              "Christian Dem", "Poujadists"),
                     name="Party") +
  labs(x="First Dimension", y="Second Dimension")

# Function to convert degrees to radians for rotation calculations
deg2rad <- function(x) x * pi / 180
rad45 <- deg2rad(45) # Calculate 45 degrees in radians

# Define a 2x2 rotation matrix to rotate the plot by 45 degrees
A <- matrix(c(cos(rad45), -sin(rad45),
              sin(rad45), cos(rad45)),
            nrow=2, ncol=2, byrow=TRUE)

# Recode party labels again for the rotated plot
pb <- rc$legis.data$PAR
pb <- car::recode(pb, '1="Communitsts"; 2="Socialists";
     5="Christian Dems"; 7="Poujadists"; else=NA', as.factor=TRUE)

# Plot the rotated 2-dimensional OC coordinates
plot_oc_coords(result, pb, dropNV=TRUE, ptSize=3, rotMat=A) +
  theme_bw() +
  coord_fixed() + # Fix aspect ratio
  scale_shape_manual(values=c("C", "S", "D", "P"),
                     labels=c("Communist", "Socialist",
                              "Christian Dem", "Poujadists"),
                     name="Party") +
  scale_color_manual(values=gray.colors(5),
                     labels=c("Communist", "Socialist",
                              "Christian Dem", "Poujadists"),
                     name="Party") +
  labs(x="First Dimension", y="Second Dimension") +
  theme(aspect.ratio=1, legend.position="bottom")

# Roll Call Level Analysis for Regulation of Labor Conflicts vote (ID V3090)

# Identify the column index for Roll Call ID "V3090" in the dataset
which(colnames(rc$votes) == "V3090")

# Extract votes for Roll Call ID "V3090" and assign to variable 'vote'
vote <- rc$votes[, "V3090"]

# Plot the OC scaling results for this specific roll call, showing voting behavior by party
plot_oc_rollcall(result, rc, shapeVar=pb, 807, dropNV=TRUE,
                 ptSize=3, onlyErrors=FALSE) +
  theme_bw() +
  theme(aspect.ratio=1, legend.position="bottom") +
  xlim(-1.1, 1.1) + ylim(-1.1, 1.1) +
  scale_shape_manual(values=c("D", "C", "P", "S"),
                     labels=c("Christian Dems", "Communists",
                              "Poujadists", "Socialists"),
                     name="Party") +
  xlab("First Dimension (Left-Right)") +
  ylab("Second Dimension (Pro / Anti-Regime") +
  guides(shape=guide_legend(nrow=2)) +
  annotate("text", label=paste0("Yea = ", sum(vote %in% rc$codes$yea)),
           colour="gray33", x=-.9, y=1) +
  annotate("text", label=paste0("Nay = ", sum(vote %in% rc$codes$nay)),
           colour="gray67", x=-.9, y=.9) +
  annotate("text", label="Predicted\nYea",
           colour="gray33", x=.1, y=.2) +
  annotate("text", label="Predicted\nNay",
           colour="gray67", x=-.6, y=-.5)

