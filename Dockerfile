FROM analythium/r2u-quarto:20.04 AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git-core libcairo2-dev libxt-dev xvfb xauth xfonts-base libgtk2.0-dev \
    libcurl4-openssl-dev libfribidi-dev libgit2-dev libharfbuzz-dev libicu-dev \
    libpng-dev libssl-dev libtiff-dev libxml2-dev make pandoc pandoc-citeproc \
    zlib1g-dev wget && rm -rf /var/lib/apt/lists/*

# Install R packages including rmarkdown
RUN R -e 'install.packages(c("remotes", "rmarkdown", "knitr", "ggplot2", "dplyr", "devtools","Cairo","R.utils"))'

# Install system dependencies including wget
RUN apt-get update && apt-get install -y \
    wget \
    git-core \
    libcairo2-dev \
    libxt-dev \
    xvfb \
    xauth \
    xfonts-base \
    libgtk2.0-dev \
    libcurl4-openssl-dev \
    libfribidi-dev \
    libgit2-dev \
    libharfbuzz-dev \
    libicu-dev \
    libpng-dev \
    libssl-dev \
    libtiff-dev \
    libxml2-dev \
    make \
    pandoc \
    pandoc-citeproc \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
    
# Set default CRAN repo and other R options
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/ && \
    echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | \
    tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site

# Install R packages
RUN R -e 'install.packages("remotes")'
# Add other R packages as needed

# Install Quarto
RUN wget -qO quarto.deb "https://quarto.org/download/latest/quarto-linux-amd64.deb" && \
    dpkg -i quarto.deb && \
    rm quarto.deb

# Install necessary R packages with specified versions
RUN R -e 'install.packages(c("knitr", "rmarkdown", "ggplot2", "dplyr", "devtools", "Cairo", "R.utils"))' && \
    R -e 'if (packageVersion("xfun") < "0.39") install.packages("xfun")'
    
RUN R -e 'if (packageVersion("htmltools") < "0.5.7") install.packages("htmltools")'


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
    
# Build the Quarto project
RUN quarto render --verbose

# Use a single RUN command to avoid layer issues
RUN mkdir /public && cp -r /home/fennica/inst/examples/_book/* /public

# Set up the runtime environment with nginx
FROM nginxinc/nginx-unprivileged:latest
COPY --from=builder /public /usr/share/nginx/html
EXPOSE 8080

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
