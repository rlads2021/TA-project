Rscript -e 'knitr::spin("analysis.R", knit = FALSE)'
Rscript -e 'rmarkdown::render("analysis.Rmd")'
rm analysis.Rmd
mv analysis.html ../../../../docs/analysis2.html
