# For info on Travis R scripts, see
# http://jtleek.com/protocols/travis_bioc_devel/

# Roxygen tips:
# http://r-pkgs.had.co.nz/man.html

#~/bin/R-3.5.1/bin/R CMD BATCH document.R
~/bin/R-3.5.1/bin/R CMD build ../../ --no-build-vignettes #--no-tests
#~/bin/R-3.5.1/bin/R CMD build ../../ 
#~/bin/R-3.5.1/bin/R CMD check fennica_0.0.1.tar.gz
~/bin/R-3.5.1/bin/R CMD check --as-cran fennica_0.2.1.tar.gz --no-tests
~/bin/R-3.5.1/bin/R CMD INSTALL fennica_0.2.1.tar.gz
#~/bin/R-3.5.1/bin/R CMD BATCH document.R
