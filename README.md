Fennica: Harmonized Finnish national bibliography
============================================

This repository contains code for cleaning, enriching and automatically generating reports on the Finnish national bibliography, [Fennica](https://www.kansalliskirjasto.fi/fi/palvelut/fennica-suomen-kansallisbibliografia). 

The live document is deployed in a CSC Rahti container:
[https://fennica-fennica.rahtiapp.fi](https://fennica-fennica.rahtiapp.fi)
The generated bookdown document consists of several different sections, or "chapters". Sections focus on different fields from the MARC formatted raw data [MARC](https://marc21.kansalliskirjasto.fi).
Most chapters also have visualizations that give a quick glance on what the data looks like. Processed CSV datasets can also be downloaded for further analyses.

This README describes how to reproduce the analyses and generate the notebook.

### Origins of data
The data was downloaded from The National Metadata Repository Melinda. 
See more: [https://melinda.kansalliskirjasto.fi/](https://melinda.kansalliskirjasto.fi/F/?func=find-b-0&CON_LNG=fin&local_base=fin01_opac)


## Reproducing the workflow or How to create ["Fennica metadata conversions"](https://fennica-fennica.rahtiapp.fi/) from scratch. 

**1. Clone the repository to your computer.**

```
# In terminal / GIT
git clone https://github.com/fennicahub/fennica.git
```

**2. Download dataset from the National Library website**

[collect.py](https://github.com/fennicahub/fennica/blob/master/inst/examples/field_picking/collect.py)
The script was provided to us by Osma Suominen (The National Library of Finland).

**3. Transform raw data into a readable csv format using Python scripts one by one**

[full_fennica_file.py](https://github.com/fennicahub/fennica/blob/master/inst/examples/field_picking/full_fennica_file.py)

[raw_fennica_transform.py](https://github.com/fennicahub/fennica/blob/master/inst/examples/field_picking/raw_fennica_transfom.py)

[combine_csv.py](https://github.com/fennicahub/fennica/blob/master/inst/examples/field_picking/combine_csv.py)

**4. Pick priority fields from the transformed file**

[pick_fields.py](https://github.com/fennicahub/fennica/blob/master/inst/examples/field_picking/pick_fields.py)

**5. Run [init.R](https://github.com/fennicahub/fennica/blob/master/inst/examples/init.R) to collect priority fields into a main data frame in R-Studio**

**6. Run script <field.R> in fennica/inst/examples to harmonize each field separately and to create summary tables** 

[language.R](https://github.com/fennicahub/fennica/blob/master/inst/examples/language.R)

[publication_time.R](https://github.com/fennicahub/fennica/blob/master/inst/examples/publication_time.R)

[title.R](https://github.com/fennicahub/fennica/blob/master/inst/examples/title.R)

[title_uniform.R](https://github.com/fennicahub/fennica/blob/master/inst/examples/title_uniform.R)

**7. Main polish functions to clean and harmonize different types of data field in fennica/R**

[polish_years.R](https://github.com/fennicahub/fennica/blob/master/R/polish_years.R) 

[polish_languages.R](https://github.com/fennicahub/fennica/blob/master/R/polish_languages.R)

[polish_title.R](https://github.com/fennicahub/fennica/blob/master/R/polish_title.R)

**8. Render qmd file for each <field.qmd> in fennica/inst/examples**

[publication_time.qmd](https://github.com/fennicahub/fennica/blob/master/inst/examples/publication_time.qmd)
  
[language.qmd](https://github.com/fennicahub/fennica/blob/master/inst/examples/language.qmd)

[title.qmd](https://github.com/fennicahub/fennica/blob/master/inst/examples/title.qmd)

[title_uniform.qmd](https://github.com/fennicahub/fennica/blob/master/inst/examples/title_uniform.qmd)
  
**9. Render the whole notebook from R-Studio terminal. How to render [here](https://github.com/fennicahub/fennica/blob/master/README_render_fennica.md)**

``` r
quarto render
```
  
**to render a single file**

``` r
quarto render <field_name>.qmd
```
10. Upload summary tables to Allas by running a allas.R script

[allas.R](https://github.com/fennicahub/fennica/blob/master/inst/examples/allas.R)



## 
![Description of the Webhook workflow, image from CSC Documentation](man/figures/trigger.drawio.jpeg)

The bookdown document is rendered with [GitHub Actions](https://github.com/fennicahub/fennica/blob/master/.github/workflows/fennica.yml). The generated files are placed in [gh-pages branch](https://github.com/fennicahub/fennica/blob/master/.github/workflows/static.yml) in the GitHub Repository. The generated files are copied to Rahti [by utilizing a webhook](https://docs.csc.fi/cloud/rahti/tutorials/webhooks/) and are hosted on an nginx server.

### Earlier material

Links to notebooks that are not actively maintained but may contain useful information regarding related past work.

 * [Fennica: a generic overview](https://github.com/fennicahub/fennica/blob/master/inst/examples/overview.md)
 * Presentation slide templates ([PDF](https://github.com/fennicahub/fennica/blob/master/inst/examples/slidetemplates.pdf)) and [code](https://github.com/fennicahub/fennica/blob/master/inst/examples/slidetemplates.Rmd)
 * A Quantitative Approach to Book Printing in Sweden and Finland, 1640–1828 [Source code for the figures](https://github.com/fennicahub/fennica/blob/master/inst/examples/201808-HistoricalMethods-Figures.Rmd)
 * Knowledge production in Finland 1470-1828: Digital Humanities 2016 conference presentation slides ([PDF](https://github.com/fennicahub/fennica/blob/master/inst/examples/20160715-Krakow-Fennica.pdf)) and [code](https://github.com/COMHIS/fennica/blob/master/inst/examples/20160715-Krakow-Fennica.Rmd)
 * [Figures and analyses for CCQ2019](https://gitlab.com/COMHIS/CCQ2018/blob/master/Figures.pdf)

The analyses cover several steps including XML parsing, data harmonization, removing unrecognized entries, enriching and organizing the data, carrying out statistical summaries, analysis, visualization and automated document generation.

### Licensing

The analyses and full [source code](https://github.com/fennicahub/fennica/blob/master/inst/examples/main.R)) are provided in this repository and can be freely reused under the [BSD 2 clause](https://opensource.org/licenses/BSD-2-Clause) (FreeBSD) open source licence. The analyses are based on [R](http://r-project.org) and rely on various R packages.

The original data has been published openly by National Library of Finland.


### Acknowledgements

The project is now developed based on research and infrastructure funding from the Research Council of Finland (DHL-FI and FIN-CLARIAH). The work is based on past and present collaboration between and [Turku Data Science Group](http://datascience.utu.fi) (University of Turku), [Helsinki Computational History Group (COMHIS)](http://comhis.github.io/) (University of Helsinki) and [National library of Finland](https://www.kansalliskirjasto.fi/en/) (Fennica data collection). For the list of contributors, see [contributors](https://github.com/fennicahub/fennica/graphs/contributors) and the related publications.



### Contact

Email: yulia.matveeva@utu.fi / leo.lahti@iki.fi

The project is under active open development:

  * [Issues and bug reports](https://github.com/fennicahub/fennica/issues)
  * [Pull requests](https://github.com/fennicahub/fennica/pulls) (we will acknowledge contributions)
