# # Download the csv file
url <- "https://a3s.fi/swift/v1/AUTH_3c0ccb602fa24298a6fe3ae224ca022f/fennica-container/output.tables/harmonized_fennica.csv"
# 
# Read the CSV file, explicitly setting the first column to character
# Count the number of columns in the file
column_count <- ncol(read.csv(url, nrows = 1, sep = "\t"))
#Create colClasses with 'character' for the first column and 'default' for the rest
col_classes <- c("character", rep(NA, column_count - 1))

# Read the file with the specified colClasses
df  <- read.csv(url, header = TRUE, sep = "\t", quote = "", stringsAsFactors = FALSE, colClasses = col_classes)

df2 <- df

df <- df2
df$gender <- gsub("male;female", "unisex", df$gender)
df$gender <- gsub("female;male", "unisex", df$gender)

df$publisher <- gsub("University of Helsinki", "Helsingin yliopisto", df$publisher)
df <- df %>%
  filter(melinda_id %in% melindas_19) %>%
  filter(data_element == "Kirjat" | is.na(data_element)) 

df <- df %>%
  mutate(gender = as.character(gender)) %>%
  filter(gender %in% c("male", "female"))

df$gender <- as.factor(df$gender)
no_genre <- df %>%
  filter(genre_008 == "Ei koodattu" | is.na(genre_008))

genre_pos <- df %>%
  filter(genre_008 != "Ei koodattu" & !is.na(genre_008))

df_lin <- genre_pos %>%
  mutate(title = paste(title, title_remainder, sep = " ")) %>%
  select(
    id = melinda_id,
    genre8 = genre_008,
    publisher,
    title,
    gender, 
    publication_decade, 
    publication_place, 
    language, 
    language_primary
  )

kauno <- c("Draama", "Esseet", "Huumori, satiiri", 
           "Kaunokirjallisuus", "Kirjeet", "Novellit, kertomukset", 
           "Puheet, esitelmät", "Romaanit", "Runot", "Yhdistelmä")

df_lin <- df_lin %>% mutate(code_genre = ifelse(genre8 %in% kauno, 0, 1))
df_lin$code_genre <- df_lin$code_genre


###############log regression ################
df_lin$publication_decade <- df_lin$publication_decade
#df_lin$language_primary <- as.factor(df_lin$language_primary)
model1 <- glm(
  code_genre ~ gender + publication_decade,
  data = df_lin,
  family = binomial
)
model1     
summary(model1)

library(brms)
fit.bayes <- brm(code_genre ~ gender + publication_decade, family=bernoulli(link="logit"), data=df_lin,      
                 prior = prior(normal(0,10), class=Intercept) +
                 prior(normal(0, 10), class=b))  
summary(fit.bayes)
plot(fit.bayes)

#try laplace with variables such language, publisher, publication place

# multiple plots of histograms of parameters' posteriors 
hist(beta0, nclass=20) #   arranged in a 2x2 setup
hist(beta1, nclass=20) # histogram of posterior distribution of beta1, the NV effect
hist(beta2, nclass=20);  hist(beta3, nclass=20)

library(bayesplot)
mcmc_hist(fit.bayes, pars=c("b_gendermale", "b_publication_decade1850", "b_publication_decade1860")) # posterior distributions
posterior_interval(fit.bayes, prob=0.99) 

install.packages("glmnet")
install.packages("Rcpp")

library(glmnet)
library(dplyr)
library(forcats)

# 1) Treat missing as a real level on ALL categorical predictors
cats <- c("gender","publisher", "publication_decade", "language_primary", "publication_place") 
          
df2 <- df_lin %>%
  mutate(across(all_of(cats), ~ fct_na_value_to_level(factor(.x), "Missing")))

# 2) Build numeric design matrix (drops intercept)
x <- model.matrix(~ gender + publication_decade + publisher + language_primary +  publisher + publication_place, data = df2)[, -1, drop = FALSE]
#language_primary +  publisher + publication_place
# 3) Binary response (factor with exactly 2 levels)
y <- factor(df2$code_genre)          # ensure factor
stopifnot(nlevels(y) == 2)      # sanity check


# 4) Fit lasso logistic regression
fit.lasso <- glmnet(x, y, alpha = 1, family = "binomial")
summary(fit.lasso)
plot(fit.lasso, "lambda")
set.seed(3)
cv <- cv.glmnet(x, y, alpha=1, family="binomial") 
cv$lambda.min
cv$lamba.1se

fit <- glmnet(x, y, alpha = 1, family = "binomial", lambda = 0.)

# extract coefficients at that lambda
coefs <- coef(fit.lasso)
coefs
# indices of nonzero coefficients
nz_index <- which(coefs != 0)

# extract names and values
nonzero_coefs <- data.frame(
  variable = rownames(coefs)[nz_index],
  coefficient = coefs[nz_index]
)

print(nonzero_coefs)

