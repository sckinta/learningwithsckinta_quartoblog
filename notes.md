https://albert-rapp.de/posts/13_quarto_blog_writing_guide/13_quarto_blog_writing_guide.html


- options: eval, echo, output, warning, error, include
https://quarto.org/docs/computations/execution-options.html
  - global set options in YAML
```YAML
execute:
  echo: true
  warning: false
```
  - code-specific options
```R
#| echo: false
```
