# geomask: enmascaramiento espacial en R

Paquete en desarrollo para aplicar **geomasking** reproducible a datos puntuales sensibles, con métricas de **privacidad** y **utilidad** integradas.

## Instalación

```r
devtools::install_github("JDConejeros/geomask")
```

## Ejemplo (Región Metropolitana)

Los datos incluidos (`geomask_pts`) son **sintéticos**, generados a partir de la distribución espacial de establecimientos de salud abiertos (DEIS) en Santiago, sin casos reales identificables.

```r
library(geomask)
data(geomask_pts)
data(geomask_boundary)

enmascarado <- mask_context_aware(
  geomask_pts,
  method = mask_donut,
  boundary = geomask_boundary,
  min_r = 350,
  max_r = 1000,
  seed = 2026
)

# Métrica sugerida: Location Protection Metric (LPM)
privacy_location_protection(geomask_pts, enmascarado, d_min = 350, r = 600, k_target = 4)

# Anonimización basada en grafos (k-componentes)
mask_graph_k_component(geomask_pts, k = 6, knn = 10, seed = 1)
```

## Tutoriales

Compilar vignettes:

```r
devtools::build_vignettes()
```

Artículos incluidos:

1. Introducción (`intro-geomask`)
2. Trade-off privacidad-utilidad
3. Masking context-aware
4. Reporte reproducible

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) y materiales del taller rOpenSci Champions (usethis, devtools, testthat, pkgdown).
