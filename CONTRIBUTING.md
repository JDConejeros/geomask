# Guia de contribucion (geomask)

Gracias por interesarte en **geomask**. Este proyecto sigue prácticas recomendadas en [R Packages (2e)](https://r-pkgs.org/), el taller [desarrollo de paquetes](https://desarrollo-paquetes-basico-2026.netlify.app/session-3/) y la [guía de contribución de rOpenSci](https://contributing.ropensci.org/welcome.html).

## Cómo contribuir

1. Abre un *issue* describiendo el bug o la mejora.
2. Haz fork del repositorio y crea una rama (`feat/mi-mejora`).
3. Asegura que los tests pasen: `devtools::test()`.
4. Verifica el paquete: `devtools::check()`.
5. Documenta funciones con roxygen2 (`devtools::document()`).
6. Abre un Pull Request con descripción clara y referencias.

## Entorno de desarrollo

```r
install.packages(c("devtools", "usethis", "testthat", "roxygen2"))
devtools::load_all()
devtools::test()
```

### Datos internos

Regenerar datos de ejemplo (requiere `RC-ref/Data` local):

```r
source("data-raw/prepare_data.R")
```

## Estilo de código

- Funciones exportadas: nombres en inglés (`mask_donut`).
- Comentarios y vignettes: español (por ahora).
- Usar `cli` para errores informativos.
- Preferir `sf` con CRS proyectado para distancias en metros.

## Revisión rOpenSci

Antes de la submisión formal, revisar el [devguide](https://devguide.ropensci.org/) y mantener:

- `NEWS.md` actualizado
- Cobertura de tests razonable (`covr`)
- Vignettes compilables
- Política de privacidad en datos de ejemplo (solo sintéticos o agregados)

## Conducta

Participantes deben seguir [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
