# geomask (development version)

## geomask 0.0.0.9000

* Estructura inicial del paquete (R/ tests/ vignettes/ data-raw/).
* Métodos de geomasking: random, donut, gaussian, density-aware, adaptive aggregation, location swapping, graph k-component.
* Métricas de privacidad: k-anonimato espacial, riesgo de divulgación, LPM (Location Protection Metric).
* Métricas de utilidad: NND, Ripley K, Moran/LISA (via `spdep`), resumen epidemiológico.
* Configuración YAML (`geomask_config`) y `mask_report()`.
* Datos de ejemplo RM: `geomask_pts`, `geomask_boundary`, `geomask_services`, `geomask_pop`.
* CI: R-CMD-check, pkgdown, cobertura (Codecov).
* Documentación en español (vignettes y comentarios).
