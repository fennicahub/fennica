y = rnorm(10,5,2)
hist(y)

y = rpois(100,lambda = 5)


SAMPLES = replicate(5000, rpois(1000,lambda = 5))
dim(SAMPLES)

yhat = mean(SAMPLES[,1])
YBAR = colMeans(SAMPLES)
hist(YBAR)



curve(dgamma(x,shape = 200,
             rate = 40),
      from = 20)

E(Y) = alpha/beta


# known sigma2 
posterior_N <- function(y, m0, s02, s2){
  n <- length(y)
  ybar <- mean(y)
  
  post_var <- 1 / ( 1/s02 + n/s2 )
  
  post_mean <- ( (ybar*s02) + (m0 * (s2/n))  )/
    ( s02 + s2/n )
  
  return(c(post_mean = post_mean,
           post_var = post_var))
}


set.seed(123)
y <- rnorm(n = 50, mean = 10, sd = 1) # known variance of 1
#data
hist(y,breaks = 10)

## prior
# mu ~ N( )
m0  <- 0
s02 <- 3 
curve(dnorm(x,
            m0,
            sqrt(s02)),from = -10,10)


posterior_N(y = y,
            m0 = 0,
            s02 = 3,
            s2 = 1)


draw_update <- function(y,m0,s02,s2){
  
  hist(y,xlim = c(-15,15),freq = F)
  curve(dnorm(x,m0,sqrt(s02)),add = T,lwd=2,col=2)
  post_par <- posterior_N(y = y,
                          m0 = m0,
                          s02 = s02,
                          s2 = s2)
  cat(post_par)
  curve(dnorm(x,post_par[1],
              sqrt(post_par[2])),add = T,lwd=2,col=4)
}


draw_update(y, -15, 30, 1)

