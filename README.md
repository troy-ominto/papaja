papaja: Create APA manuscripts with R Markdown
================

<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![Build status](https://travis-ci.org/crsh/papaja.svg?branch=master)](https://travis-ci.org/crsh/papaja)

`papaja` is a R-package in the making including a [R Markdown](http://rmarkdown.rstudio.com/) template that can be used with (or without) [RStudio](http://www.rstudio.com/) to produce documents, which conform to the American Psychological Association (APA) manuscript guidelines (6th Edition). The package uses the LaTeX document class [apa6](http://www.ctan.org/pkg/apa6) and a .docx-reference file, so you can create PDF documents, or Word documents if you have to. Moreover, `papaja` supplies R-functions that facilitate reporting results of your analyses in accordance with APA guidelines.

**Note, at this point `papaja` is in active development and should be considered alpha. If you experience any problems, please [open an issue](https://github.com/crsh/papaja/issues) on Github.**

Examples
--------

Take a look at the [.Rmd](https://github.com/crsh/papaja/blob/master/example/example.Rmd) of the example manuscript in the folder `example` and the resulting [.pdf](https://raw.githubusercontent.com/crsh/papaja/master/example/example.pdf). The example document also contains some basic instructions.

Installation
------------

### Requirements

To use `papaja` you need to make sure the following software is installed on your computer:

-   [R](http://www.r-project.org/) (2.11.1 or later)
-   [RStudio](http://www.rstudio.com/) (0.98.932 or later) is optional; if you don't use RStudio, you need to install [pandoc](http://johnmacfarlane.net/pandoc/) using the [instructions for your operating system](https://github.com/rstudio/rmarkdown/blob/master/PANDOC.md)
-   A [TeX](http://de.wikipedia.org/wiki/TeX) distribution (2013 or later; e.g., [MikTeX](http://miktex.org/) for Windows, [MacTeX](https://tug.org/mactex/) for Mac, obviously, or [TeX Live](http://www.tug.org/texlive/) for Linux).
    -   **Windows** users should use MikTex if possible. Currently, pandoc and the Windows version of Tex Live [don't seem to like each other](https://github.com/rstudio/rmarkdown/issues/6). Make sure you install the *complete*---not the basic---version.
    -   **Ubuntu 14.04** users need a few additional TeX packages for the document class `apa6` to work:

``` {sh}
sudo apt-get install texlive texlive-publishers texlive-fonts-extra texlive-latex-extra texlive-humanities lmodern
```

### Install papaja

Once all that is taken care of, install `papaja` from GitHub:

``` {r}
devtools::install_github("crsh/papaja")
```

How to use papaja
-----------------

Once `papaja` is installed, you can select the APA template when creating a new Markdown file through the RStudio menus.

![APA template selection](inst/images/template_selection.png)

If you want to add citations specify your BibTeX-file in the YAML front matter of the document (`bibliography: my.bib`) and you can start citing. If necessary, have a look at R Markdown's [overview of the citation syntax](http://rmarkdown.rstudio.com/authoring_bibliographies_and_citations.html).

### Helper functions to report analyses

The functions `apa_print()` and `apa_table()` facilitate reporting results of your analyses. Take a look at the [.Rmd](https://github.com/crsh/papaja/blob/master/example/example.Rmd) of the example manuscript in the folder `example` and the resulting [.pdf](https://raw.githubusercontent.com/crsh/papaja/master/example/example.pdf).

Drop a supported analysis result, such as an `htest`- or `lm`-object, into `apa_print()` and receive a list of possible character strings that you can use to report the results of your analysis.

``` r
my_lm <- lm(Sepal.Width ~ Sepal.Length + Petal.Width + Petal.Length, data = iris)
apa_lm <- apa_print(my_lm)
```

One element of this list is `apa_lm$table` that, in the case of an `lm`-object, will contain a complete regression table. Pass `apa_lm$table` to `apa_table()` to turn it into a proper table in your PDF or Word document (remember to set the chunk option `results = "asis"`).

``` r
apa_table(apa_lm$table, caption = "Iris regression table.")
```

<!-- GitHub markdown doesn't support MathJax -->

------------------------------------------------------------------------

Table. *Iris regression table.*

| Predictor    |  *b*  |      95% CI      | *t(146)* |    *p*    |
|:-------------|:-----:|:----------------:|:--------:|:---------:|
| Intercept    |  1.04 |  \[0.51, 1.58\]  |   3.85   | &lt; .001 |
| Sepal Length |  0.61 |  \[0.48, 0.73\]  |   9.77   | &lt; .001 |
| Petal Width  |  0.56 |  \[0.32, 0.80\]  |   4.55   | &lt; .001 |
| Petal Length | -0.59 | \[-0.71, -0.46\] |   -9.43  | &lt; .001 |

------------------------------------------------------------------------

<!--
`papaja` currently provides methods for the following object classes:


A           A-L       L-S                 S                
----------  --------  ------------------  -----------------
afex_aov    aovlist   lm                  summary.aovlist  
anova       glht      lsmobj              summary.glht     
Anova.mlm   htest     summary.Anova.mlm   summary.lm       
aov         list      summary.aov         summary.ref.grid 
-->
Be sure to also check out `apa_barplot()` and `apa_beeplot()` if you work with factorial designs. If you prefer creating your plots with `ggplot2` try `theme_apa()`.

### Using papaja without RStudio

Don't use RStudio? No problem. Use the `rmarkdown::render` function to create articles:

``` {r}
# Create new R Markdown file
rmarkdown::draft(
  "mymanuscript.Rmd"
  , "apa6"
  , package = "papaja"
  , create_dir = FALSE
  , edit = FALSE
)

# Render manuscript
rmarkdown::render("mymanuscript.Rmd")
```

Known issues
------------

-   The references in Word violate the APA guidelines in that there is no hanging indentation (i.e. indentation of all lines but the first one). As of now there is no fix for this problem.
-   In-text citation incorrectly use ampersands instead of "and". This is a current limitation of the [pandoc-citeproc](https://hackage.haskell.org/package/pandoc-citeproc) filter. I'm still looking for ways to fix this.
-   Citations may mess with RStudios syntax highlighting in the current line. Incorrect highlighting following a citation does not necessarily indicate incorrect syntax.
-   Printing PDF from RStudio's PDF viewer can produce weird results. If you want to print your manuscript I suggest you use any other PDF viewer of your choice.

Contribute
----------

Like `papaja` and want to contribute? Take a look at the [open issues](https://github.com/crsh/papaja/issues) if you need inspiration. Other than that, there are many output objects from analysis methods that we would like `apa_print()` to support. Any new S3-methods for this function are always appreciated (e.g., `glm`, `factanal`, `fa`, `lavaan`, `BFBayesFactor`).

Papers that use papaja
----------------------

Although `papaja` is not yet on CRAN and is still undergoing a lot of changes, there are peer-reviewed publications that use it. If you have published a paper that was written with `papaja`, let me know and I will add it to this list.

Stahl, C., Barth, M., & Haider, H. (2015). Distorted estimates of implicit and explicit learning in applications of the process-dissociation procedure to the SRT task. *Consciousness & Cognition*, 37, 27–43. doi: [10.1016/j.concog.2015.08.003](http://dx.doi.org/10.1016/j.concog.2015.08.003)

Aust, F., & Edwards, J. D. (2016). Incremental validity of Useful Field of View subtests for the prediction of Instrumental Activities of Daily Living. *Journal of Clinical and Experimental Neuropsychology*, 38, 497-515. doi: [10.1080/13803395.2015.1125453](http://dx.doi.org/10.1080/13803395.2015.1125453)

Stahl, C., Haaf, J., & Corneille, O. (2016). Subliminal Evaluative Conditioning? Above-Chance CS Identification May Be Necessary and Insufficient for Attitude Learning. *Journal of Experimental Psychology: General*, 27. doi: [10.1037/xge0000191](http://dx.doi.org/10.1037/xge0000191)

Other journal templates
=======================

Obviously, not all journals require manuscripts and articles to be prepared according to APA guidelines. If you are looking for other journal article templates, the following list of `rmarkdown`/`pandoc` packages and templates may be helpful. If you know of other packages and templates, drop us a note, so we can add them here.

-   [rticles](https://github.com/rstudio/rticles): The rticles package includes a set of R Markdown templates that enable authoring of R related journal and conference submissions.
-   [Michael Sachs' pandoc journal templates](https://github.com/sachsmc/pandoc-journal-templates): Pandoc templates for the major statistics and biostatistics journals

Finally, in case you prefer to work with Python, have a look at the [Academic Markdown](https://github.com/smathot/academicmarkdown)-module.

Package dependencies
====================

![](README_files/figure-markdown_github/unnamed-chunk-5-1.png)
