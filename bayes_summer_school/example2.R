
posterior_N <- function(y, #binary vector where 1 means success
                        a0, b0){
  n <- length(y)
  post_a <- a0+10
  post_b <- b0+n-10
  return(c(post_a = post_a,
           post_b = post_b))
}


draw_update <- function(y,a0,b0){
  curve(dbeta(x,a0,b0), lwd = 2, col = 2, ylim = c(0,15))
  post_par <- posterior_N(y = y,
                          a0 = a0,
                          b0 = b0)
  post_mean <- a0/(a0+b0)
  curve(dbeta(x,post_par[1],
              post_par[2]),add = T,lwd=2,col=4)
  print(post_par)
  print(post_mean)
}

y <- c(rep(0,1000), rep(1,5000))

draw_update(y, a0 = 1, b0 = 1)

draw_update(y, a0 = 0.5, b0 = 0.03)

draw_update(y, a0 = 0.9, b0 = 0.1)


