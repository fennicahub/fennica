## Steps to render fennica quarto book

To work with the fennica quarto book

**1. clone the repository using the command**

``` r
git clone https://github.com/fennicahub/fennica.git
```

**2. Open it with R-studio and at the terminal of R-studio render the book using**

``` r
quarto render
```
  
**to render a single file**

``` r
quarto render author_name.qmd
```

After rendering it locally and everything goes well you can push the changes as follows

**3.First add**

``` r
git add .
```

**4.commit it as follows**

``` r
git commit -am "commit message"
```

**5.push it to the branch**

``` r
git push origin master
```

If there has been changes/updates at the git repository first fetch the changes before commit using

``` r
git fetch --all
```

and then you need to merge it with your local using

``` r
git merge origin master
```
