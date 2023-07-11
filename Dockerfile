FROM rocker/r-ver:4.2.1 AS builder
RUN apt-get update && apt-get install -y  git-core libcairo2-dev libxt-dev xvfb xauth xfonts-base libgtk2.0-dev libcurl4-openssl-dev libfribidi-dev libgit2-dev libharfbuzz-dev libicu-dev libpng-dev libssl-dev libtiff-dev libxml2-dev make pandoc pandoc-citeproc zlib1g-dev && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN R -e 'install.packages("remotes")'
RUN Rscript -e 'remotes::install_version("stringr",upgrade="never", version = "1.4.1")'
RUN Rscript -e 'remotes::install_version("knitr",upgrade="never", version = "1.40")'
RUN Rscript -e 'remotes::install_version("rmarkdown",upgrade="never", version = "2.16")'
RUN Rscript -e 'remotes::install_version("bookdown",upgrade="never", version = "0.29")'
RUN Rscript -e 'remotes::install_version("gridExtra",upgrade="never", version = "2.3")'
RUN Rscript -e 'remotes::install_version("testthat",upgrade="never", version = "3.1.4")'
RUN Rscript -e 'remotes::install_version("Cairo",upgrade="never", version = "1.6-0")'
RUN Rscript -e 'remotes::install_version("R.utils",upgrade="never", version = "2.12.0")'
RUN Rscript -e 'remotes::install_version("ggplot2",upgrade="never", version = "3.3.6")'
RUN Rscript -e 'remotes::install_version("remotes",upgrade="never", version = "2.4.2")'
RUN Rscript -e 'remotes::install_version("tm",upgrade="never", version = "0.7-8")'
RUN Rscript -e 'remotes::install_version("XML",upgrade="never", version = "3.99-0.10")'
RUN Rscript -e 'remotes::install_version("stringdist",upgrade="never", version = "0.9.8")'
RUN Rscript -e 'remotes::install_version("dplyr",upgrade="never", version = "1.0.10")'
RUN Rscript -e 'remotes::install_version("data.table",upgrade="never", version = "1.14.2")'
RUN Rscript -e 'remotes::install_github("comhis/comhis")'
RUN mkdir /build_zone
ADD . /build_zone
WORKDIR /build_zone
RUN rm -rf /build_zone
COPY . /home/fennica
WORKDIR /home/fennica
RUN R -e 'remotes::install_local(upgrade="never")'
WORKDIR /home/fennica/inst/examples
RUN chgrp -R 0 /home/fennica && \
    chmod -R g=u /home/fennica
RUN R -e 'bookdown::render_book("index.Rmd", "bookdown::gitbook")' && \
    mv _book /public
FROM nginxinc/nginx-unprivileged:latest
COPY --from=builder /public /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
