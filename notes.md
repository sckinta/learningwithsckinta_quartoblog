https://albert-rapp.de/posts/13_quarto_blog_writing_guide/13_quarto_blog_writing_guide.html

-   options: eval, echo, output, warning, error, include https://quarto.org/docs/computations/execution-options.html

    -   global set options in YAML

    ``` yaml
    execute:
    echo: true
    warning: false
    ```

    -   code-specific options

    ``` r
    #| echo: false
    ```

# publish from github repo at netlify

https://quarto.org/docs/publishing/netlify.html#publish-from-git-provider
