# Plan de Trabajo: `geomask` — Spatial Geomasking and Anonymization Tools for R

> **Repositorio:** https://github.com/JDConejeros/geomask
> **Autor:** José Daniel Conejeros (`jo.conejeros@gmail.com`, ORCID: 0000-0003-3402-4361)
> **Versión actual:** 0.0.0.9000 (fase conceptual / early development)
> **Licencia:** MIT
> **Horizonte:** Junio 2025 – Abril 2027

---

## Tabla de Contenidos

1. [Visión general del paquete](#1-visión-general-del-paquete)
2. [Estructura del repositorio](#2-estructura-del-repositorio)
3. [Dependencias](#3-dependencias)
4. [Datos incluidos y de referencia](#4-datos-incluidos-y-de-referencia)
5. [Funciones planificadas: especificación matemática](#5-funciones-planificadas-especificación-matemática)
   - 5.1 Métodos de geomasking
   - 5.2 Métricas de privacidad
   - 5.3 Métricas de utilidad
   - 5.4 Funciones auxiliares y context-aware
6. [Testing y control de calidad](#6-testing-y-control-de-calidad)
7. [Documentación y vignettes](#7-documentación-y-vignettes)
8. [Flujos de trabajo reproducibles](#8-flujos-de-trabajo-reproducibles)
9. [Difusión y construcción de comunidad](#9-difusión-y-construcción-de-comunidad)
10. [Revisión rOpenSci](#10-revisión-ropensci)
11. [Checklist mensual (Junio 2025 – Abril 2027)](#11-checklist-mensual-junio-2025--abril-2027)

---

## 1. Visión general del paquete

`geomask` es un marco unificado, reproducible y extensible en R para aplicar, evaluar y documentar estrategias de **geomasking** (enmascaramiento espacial) en datos georreferenciados sensibles. Su objetivo central es reducir el riesgo de reidentificación de individuos a partir de sus coordenadas geográficas, manteniendo al mismo tiempo la utilidad analítica del dataset para investigación epidemiológica, clínica y en ciencias sociales.

El paquete trabaja con objetos `sf` (Simple Features) y está diseñado para ser interoperable con el ecosistema espacial moderno de R (`sf`, `terra`, `spdep`).

### Principios de diseño

- **Balance privacidad / utilidad:** toda función de masking incluye su contraparte de evaluación.
- **Reproducibilidad:** el paquete debe permitir documentar todos los parámetros y semillas utilizados.
- **Transparencia:** los métodos deben poder reportarse en artículos científicos con suficiente detalle metodológico.
- **Contexto-sensibilidad:** los desplazamientos deben respetar información geográfica real (densidad, uso de suelo, límites administrativos).
- **Ciencia abierta responsable:** materiales bilingües (ES/EN), código abierto, casos de uso reproducibles.

---

## 2. Estructura del repositorio

```
geomask/
├── R/                        # Funciones del paquete
│   ├── geomasking.R          # Métodos de masking (donut, gaussian, density-aware, etc.)
│   ├── privacy_metrics.R     # k-anonimato espacial, riesgo de divulgación
│   ├── utility_metrics.R     # Métricas de pérdida de utilidad
│   ├── context_aware.R       # Masking informado por contexto geográfico
│   ├── reporting.R           # Herramientas de reporte reproducible
│   └── utils.R               # Funciones auxiliares internas
├── man/                      # Documentación roxygen2 (generada)
├── tests/
│   ├── testthat/
│   │   ├── test-geomasking.R
│   │   ├── test-privacy_metrics.R
│   │   ├── test-utility_metrics.R
│   │   └── test-context_aware.R
│   └── testthat.R
├── vignettes/
│   ├── intro-geomask.Rmd         # Introducción general
│   ├── privacy-utility-tradeoff.Rmd
│   ├── context-aware-masking.Rmd
│   └── reproducible-reporting.Rmd
├── data/                     # Datos incluidos en el paquete
├── data-raw/                 # Scripts para generar/limpiar datos internos
├── .github/
│   └── workflows/
│       ├── R-CMD-check.yaml
│       └── pkgdown.yaml
├── DESCRIPTION
├── NAMESPACE
├── NEWS.md
├── README.md
├── _pkgdown.yml
├── CODE_OF_CONDUCT.md
└── CONTRIBUTING.md
```

---

## 3. Dependencias

### Dependencias principales (`Imports`)

| Paquete   | Rol                                                               |
| --------- | ----------------------------------------------------------------- |
| `sf`    | Manipulación de geometrías espaciales (puntos, polígonos, CRS) |
| `units` | Manejo de unidades métricas para distancias de desplazamiento    |
| `dplyr` | Manipulación de atributos en tablas de `sf`                    |
| `rlang` | Programación defensiva con NSE                                   |
| `cli`   | Mensajes de error/advertencia con formato                         |

### Dependencias sugeridas (`Suggests`)

| Paquete                 | Rol                                                   |
| ----------------------- | ----------------------------------------------------- |
| `testthat (>= 3.0.0)` | Testing unitario                                      |
| `roxygen2`            | Generación de documentación                         |
| `knitr`               | Compilación de vignettes                             |
| `rmarkdown`           | Renderización de vignettes                           |
| `pkgdown`             | Sitio web de documentación                           |
| `spdep`               | Estadísticas espaciales para evaluación de utilidad |
| `spatstat`            | Análisis de patrones de puntos (utilidad)            |
| `terra`               | Interoperabilidad con rasters (contexto poblacional)  |
| `ggplot2`             | Visualización en vignettes                           |
| `tmap`                | Mapas comparativos original/enmascarado               |

### Dependencias del sistema

- R ≥ 4.1.0
- GDAL, PROJ, GEOS (requeridos por `sf`)

---

## 4. Datos incluidos y de referencia

### Datos sintéticos incluidos en el paquete

El paquete debe incluir al menos dos datasets sintéticos para ilustrar los ejemplos y vignettes sin depender de datos sensibles reales.

**`geomask_pts`** — Puntos sintéticos de casos epidemiológicos:

- Tipo: `sf` POINT
- CRS: WGS84 (EPSG:4326) + versión proyectada (UTM)
- Variables: `id`, `fecha`, `edad_grupo`, `sexo`, `geometry`
- Fuente: generados con `fabricatr` o similar + shapefile público Chile

**`geomask_boundary`** — Polígono de límite administrativo de referencia:

- Tipo: `sf` POLYGON (comunas)
- CRS: WGS84
- Fuente: Biblioteca del Congreso Nacional de Chile (datos abiertos)

**`geomask_pop`** — Grilla de densidad poblacional de referencia:

- Tipo: `SpatRaster` (terra) o `sf` POLYGON con atributo de densidad
- Fuente: WorldPop, INE Chile, o generado sintéticamente

### Script de generación (`data-raw/`)

Todo dato interno debe tener su script de reproducción en `data-raw/` para garantizar transparencia. Usar `usethis::use_data_raw()`.

---

## 5. Funciones planificadas: especificación matemática

### 5.1 Métodos de geomasking

---

#### `mask_random_perturbation()`

**Descripción:** Desplaza cada punto en una dirección aleatoria uniforme y a una distancia aleatoria dentro de un radio máximo.

**Formulación matemática:**

Sea $\mathbf{p}_i = (x_i, y_i)$ la ubicación original del individuo $i$. Se generan:

$$
\theta_i \sim \text{Uniform}(0, 2\pi)
$$

$$
r_i \sim \text{Uniform}(0, r_{\max})
$$

La ubicación enmascarada es:

$$
\mathbf{p}_i^* = \left(x_i + r_i \cos\theta_i,\; y_i + r_i \sin\theta_i\right)
$$

**Argumentos:**

- `data`: objeto `sf` con geometría POINT
- `max_r`: radio máximo de desplazamiento (en metros si CRS proyectado)
- `seed`: semilla para reproducibilidad

**Notas:** Implementación más simple, pero sin garantías de distancia mínima. Puede reidentificar si el punto queda muy cerca del original.

---

#### `mask_donut()`

**Descripción:** Desplaza cada punto dentro de un anillo ("donut"), garantizando una distancia mínima al punto original.

**Formulación matemática:**

$$
\theta_i \sim \text{Uniform}(0, 2\pi)
$$

$$
r_i \sim \text{Uniform}(r_{\min}, r_{\max})
$$

$$
\mathbf{p}_i^* = \left(x_i + r_i \cos\theta_i,\; y_i + r_i \sin\theta_i\right)
$$

con la restricción $r_{\min} < r_i \leq r_{\max}$.

**Argumentos:**

- `data`: objeto `sf` POINT
- `min_r`: radio mínimo (distancia de protección garantizada)
- `max_r`: radio máximo
- `seed`: semilla

**Notas:** Método de uso frecuente en epidemiología espacial (p.ej. Kwan et al. 2004, Allshouse et al. 2010). La distancia mínima actúa como garantía explícita de protección.

---

#### `mask_gaussian()`

**Descripción:** Desplaza cada punto según una distribución gaussiana bidimensional, con el original como media.

**Formulación matemática:**

$$
\Delta x_i \sim \mathcal{N}(0, \sigma^2), \quad \Delta y_i \sim \mathcal{N}(0, \sigma^2)
$$

$$
\mathbf{p}_i^* = (x_i + \Delta x_i,\; y_i + \Delta y_i)
$$

La distancia de desplazamiento sigue una distribución de Rayleigh con parámetro $\sigma$:

$$
r_i = \sqrt{\Delta x_i^2 + \Delta y_i^2} \sim \text{Rayleigh}(\sigma)
$$

con valor esperado $\mathbb{E}[r_i] = \sigma\sqrt{\pi/2}$.

**Argumentos:**

- `data`: objeto `sf` POINT
- `sigma`: desviación estándar del desplazamiento (en metros si CRS proyectado)
- `seed`: semilla

**Notas:** No garantiza distancia mínima; puede resultar en desplazamientos muy pequeños. Útil cuando se quiere una distribución de desplazamientos concentrada en torno a cero.

---

#### `mask_density_displacement()`

**Descripción:** Ajusta el radio de desplazamiento en función de la densidad poblacional local. En zonas de alta densidad se aplica mayor desplazamiento.

**Formulación matemática:**

Sea $\rho(\mathbf{p}_i)$ la densidad poblacional en la ubicación $\mathbf{p}_i$ (obtenida de una grilla de referencia). Se define una función de escala:

$$
s_i = f\!\left(\frac{\rho(\mathbf{p}_i)}{\bar{\rho}}\right)
$$

donde $f(\cdot)$ es una función monótona creciente, por ejemplo:

$$
s_i = s_{\min} + (s_{\max} - s_{\min}) \cdot \Phi\!\left(\frac{\log\rho(\mathbf{p}_i) - \mu_\rho}{\sigma_\rho}\right)
$$

con $\Phi$ la CDF normal estándar aplicada a los log-densidades estandarizados.

El desplazamiento se aplica dentro de un donut con radio escalado:

$$
r_{\max,i} = r_{\text{base}} \cdot s_i, \quad r_{\min,i} = r_{\min,\text{base}} \cdot s_i
$$

**Argumentos:**

- `data`: objeto `sf` POINT
- `pop_layer`: raster o polígonos con densidad poblacional
- `r_base`: radio base de desplazamiento
- `r_min_base`: radio mínimo base
- `scale_fun`: función de escala (`"linear"`, `"logistic"`, o función personalizada)
- `seed`: semilla

---

#### `mask_adaptive_aggregation()`

**Descripción:** Agrega puntos en unidades administrativas de tamaño adaptativo para garantizar que cada celda tenga al menos $k$ individuos.

**Formulación matemática:**

Dado un conjunto de zonas $\{Z_1, \ldots, Z_m\}$ con conteos $n_j = |\{\mathbf{p}_i \in Z_j\}|$, se define:

- Si $n_j \geq k$: la zona se mantiene.
- Si $n_j < k$: la zona se fusiona con la vecina más próxima (criterio de menor distancia entre centroides o mayor adyacencia) de forma iterativa hasta que $n_j \geq k$.

El punto enmascarado $\mathbf{p}_i^*$ se reemplaza por el centroide ponderado de la zona resultante $Z_j^*$:

$$
\mathbf{p}_i^* = \frac{1}{n_j} \sum_{\mathbf{p}_\ell \in Z_j^*} \mathbf{p}_\ell
$$

o bien se utiliza el centroide geográfico de $Z_j^*$.

**Argumentos:**

- `data`: objeto `sf` POINT
- `zones`: objeto `sf` POLYGON con las zonas base
- `k`: umbral mínimo de individuos por zona
- `merge_method`: criterio de fusión (`"centroid_dist"`, `"adjacency"`)

---

#### `mask_location_swapping()`

**Descripción:** Intercambia las ubicaciones de pares de individuos que cumplen restricciones de similitud contextual (misma zona administrativa, grupo etario, etc.), preservando distribuciones marginales.

**Formulación matemática:**

Sea $\mathcal{G} = \{G_1, \ldots, G_L\}$ una partición de los individuos según variables contextuales (e.g., comuna × grupo etario). Para cada grupo $G_\ell$, se genera una permutación aleatoria $\pi_\ell$ de los índices dentro del grupo, de modo que el individuo $i$ recibe la ubicación del individuo $\pi_\ell(i)$:

$$
\mathbf{p}_i^* = \mathbf{p}_{\pi_\ell(i)}
$$

con la restricción de que $\pi_\ell(i) \neq i$ para todo $i$ (no self-swap), y adicionalmente se puede imponer:

$$
d(\mathbf{p}_i, \mathbf{p}_{\pi_\ell(i)}) \geq d_{\min}
$$

donde $d(\cdot,\cdot)$ es la distancia euclidiana o geodésica.

**Argumentos:**

- `data`: objeto `sf` POINT
- `context_vars`: nombres de columnas que definen los grupos de swap
- `min_dist`: distancia mínima de swap
- `seed`: semilla

---

### 5.2 Métricas de privacidad

---

#### `privacy_k_anonymity()`

**Descripción:** Calcula el k-anonimato espacial de cada punto enmascarado. Un punto tiene k-anonimato espacial $k$ si existen al menos $k-1$ otros puntos enmascarados dentro de un radio $r$ de él.

**Formulación matemática:**

$$
k_i(r)=\left|\left\{j\neq i:d(p_i^{*},p_j^{*})\le r\right\}\right|+1
$$

El k-anonimato global del dataset se define como:

$$
K(r) = \min_i k_i(r)
$$

Un dataset cumple $k$-anonimato espacial con radio $r$ si $K(r) \geq k$.

**Argumentos:**

- `masked`: objeto `sf` POINT enmascarado
- `r`: radio de vecindad (en metros)
- `return_individual`: lógico, si se retorna $k_i$ para cada punto

**Output:** escalar $K(r)$ y/o vector $k_i(r)$.

---

#### `privacy_disclosure_risk()`

**Descripción:** Estima el riesgo de divulgación como la probabilidad de que un adversario pueda reidentificar correctamente al individuo real a partir de su ubicación enmascarada, usando el conjunto de puntos originales como referencia.

**Formulación matemática:**

**Modelo de adversario simple (nearest neighbor):**

$$
\mathrm{RD}_i=\mathbf 1\!\left[d(p_i^{*},p_i)=\min_j d(p_i^{*},p_j)\right]
$$

El riesgo agregado es:

$$
\overline{\text{RD}} = \frac{1}{n} \sum_{i=1}^n \text{RD}_i
$$

**Modelo de adversario probabilístico:**

$$
\mathrm{RD}_i^{\mathrm{prob}}=\frac{\exp\left(-d(p_i^{*},p_i)/h\right)}{\sum_{j=1}^{n}\exp\left(-d(p_i^{*},p_j)/h\right)}
$$

con $h$ un parámetro de ancho de banda que modela la incertidumbre del adversario.

**Argumentos:**

- `original`: objeto `sf` POINT original
- `masked`: objeto `sf` POINT enmascarado
- `method`: `"nn"` (nearest-neighbor) o `"prob"` (probabilístico)
- `bandwidth`: parámetro $h$ (solo para `method = "prob"`)

---

### 5.3 Métricas de utilidad

---

#### `utility_spatial_stats()`

**Descripción:** Compara estadísticas espaciales de primer y segundo orden entre los datos originales y enmascarados.

**Formulación matemática:**

**Distancia al vecino más cercano (NND):**

$$
\text{NND}_i = \min_{j \neq i} d(\mathbf{p}_i, \mathbf{p}_j)
$$

Se comparan los vectores $\{\text{NND}_i^{\text{orig}}\}$ y $\{\text{NND}_i^{\text{mask}}\}$ mediante la estadística de Kolmogorov-Smirnov:

$$
D_{KS} = \sup_x \left|F_{\text{orig}}(x) - F_{\text{mask}}(x)\right|
$$

**Función K de Ripley:**

$$
\hat{K}(r) = \frac{|A|}{n(n-1)} \sum_{i \neq j} \mathbb{1}[d(\mathbf{p}_i, \mathbf{p}_j) \leq r] \cdot w_{ij}
$$

donde $|A|$ es el área del dominio de estudio y $w_{ij}$ es una corrección de borde. Se calcula para datos originales y enmascarados y se reporta la discrepancia integrada:

$$
\Delta K = \int_0^{r_{\max}} \left|\hat{K}_{\text{orig}}(r) - \hat{K}_{\text{mask}}(r)\right| dr
$$

**Argumentos:**

- `original`: objeto `sf` POINT original
- `masked`: objeto `sf` POINT enmascarado
- `metrics`: vector de métricas a calcular (`"nnd"`, `"ripley_k"`, `"moran"`, etc.)
- `r_seq`: secuencia de radios para K de Ripley

---

#### `utility_cluster_detection()`

**Descripción:** Evalúa si la detección de clusters espaciales (SaTScan-style o Moran local) es consistente entre los datos originales y enmascarados.

**Formulación matemática:**

**Índice de Moran Global:**

$$
I = \frac{n}{S_0} \cdot \frac{\sum_i \sum_j w_{ij}(y_i - \bar{y})(y_j - \bar{y})}{\sum_i (y_i - \bar{y})^2}
$$

donde $w_{ij}$ son los pesos espaciales, $S_0 = \sum_i \sum_j w_{ij}$, $y_i$ son los conteos en zonas $i$ (calculados a partir de los puntos), y $\bar{y}$ es la media de conteos.

Se reporta $\Delta I = |I_{\text{orig}} - I_{\text{mask}}|$ como indicador de discrepancia.

**Índice de Moran Local (LISA):**

$$
I_i = z_i \sum_j w_{ij} z_j
$$

donde $z_i = (y_i - \bar{y}) / s_y$. Se evalúa la concordancia de clasificaciones HH/LL/HL/LH entre datos originales y enmascarados.

**Argumentos:**

- `original`: objeto `sf` POINT o POLYGON
- `masked`: objeto `sf` POINT o POLYGON
- `zones`: polígonos para calcular conteos
- `weight_style`: estilo de pesos espaciales (`"queen"`, `"rook"`, `"knn"`)

---

#### `utility_epi_summary()`

**Descripción:** Calcula y compara estadísticas relevantes para epidemiología espacial: tasas por zona, suavizamiento espacial, y distribución de distancias a servicios de salud.

**Argumentos:**

- `original`: objeto `sf` POINT
- `masked`: objeto `sf` POINT
- `zones`: `sf` POLYGON con población de referencia
- `services`: `sf` POINT con ubicación de servicios de salud (opcional)

---

#### `utility_summary()` (función envolvente)

Función wrapper que calcula todas las métricas de utilidad relevantes de una vez y retorna un objeto estructurado con resultados, listo para reportar.

---

### 5.4 Funciones auxiliares y context-aware

---

#### `mask_context_aware()`

**Descripción:** Función envolvente que aplica cualquier método de masking con restricciones contextuales: (a) el punto enmascarado no puede caer fuera del límite administrativo de referencia, (b) no puede caer en zonas no habitadas (agua, parques, industria), (c) puede respetar gradientes de densidad.

**Lógica:** Aplica el método de masking elegido y, si el punto enmascarado cae en zona prohibida, re-muestrea hasta obtener una ubicación válida o hasta agotar `max_iter` intentos.

**Argumentos:**

- `data`: objeto `sf` POINT
- `method`: función de masking a aplicar (`"donut"`, `"gaussian"`, etc.)
- `boundary`: `sf` POLYGON de límite permitido
- `forbidden`: `sf` POLYGON de zonas prohibidas (opcional)
- `pop_layer`: raster de densidad poblacional (opcional)
- `max_iter`: número máximo de intentos por punto
- `...`: argumentos adicionales pasados al método de masking

---

#### `mask_report()`

**Descripción:** Genera un reporte estructurado (lista o data frame) con los parámetros usados, métricas de privacidad y utilidad, y recomendaciones de citación metodológica. Opcionalmente exporta a PDF/HTML vía `rmarkdown`.

**Output:**

```r
list(
  method       = "donut",
  parameters   = list(min_r = 500, max_r = 2000, seed = 42),
  n_points     = 1200,
  privacy      = list(k_anonymity = 8, disclosure_risk = 0.03),
  utility      = list(ks_nnd = 0.12, delta_moran = 0.04),
  timestamp    = Sys.time(),
  citation_text = "..."
)
```

---

## 6. Testing y control de calidad

### Estructura de tests (`testthat`)

Cada archivo de tests cubre las funciones del archivo `.R` correspondiente.

**Tipos de tests a implementar:**

**Tests de comportamiento correcto:**

- Verificar que el output es un objeto `sf` con el mismo número de filas que el input.
- Verificar que el CRS del output coincide con el del input.
- Verificar que todos los puntos enmascarados cumplen la restricción de distancia (para `mask_donut`: $r_i \geq r_{\min}$ para todos $i$).
- Verificar que el k-anonimato retornado es el valor mínimo correcto.
- Verificar reproducibilidad: mismos resultados con la misma semilla.

**Tests de casos borde:**

- Input con un solo punto.
- Input con puntos duplicados.
- CRS geográfico (grados) vs. proyectado (metros): verificar manejo correcto de unidades.
- `NA` en geometrías: debe lanzar error informativo.
- Radio mínimo ≥ radio máximo: debe lanzar error.

**Tests de integración:**

- Pipeline completo: masking → privacidad → utilidad → reporte.
- Interoperabilidad con `terra` para capas contextuales.

### CI/CD

El repositorio ya tiene `.github/workflows/`. Se deben configurar:

- `R-CMD-check.yaml`: checks en Ubuntu, macOS y Windows con múltiples versiones de R (release, oldrel).
- `pkgdown.yaml`: despliegue automático del sitio de documentación en `gh-pages`.
- `test-coverage.yaml`: reporte de cobertura de tests via `covr` + Codecov.

### Cobertura objetivo

Cobertura de tests ≥ 90% de líneas de código para funciones exportadas.

---

## 7. Documentación y vignettes

### Documentación de funciones (roxygen2)

Cada función exportada debe tener:

- `@title`, `@description`, `@details` (incluyendo referencia matemática)
- `@param` para cada argumento
- `@return` describiendo el objeto de salida
- `@references` con literatura metodológica relevante
- `@examples` con código ejecutable
- `@seealso` vinculando funciones relacionadas
- `@export`

### Vignettes planificadas

**`intro-geomask.Rmd`** — Introducción al paquete: motivación, instalación, ejemplo rápido con `geomask_pts`, comparación visual original vs. enmascarado.

**`privacy-utility-tradeoff.Rmd`** — Análisis del trade-off: cómo variar el radio de masking afecta las métricas de privacidad y utilidad. Incluye gráficos de curvas de Pareto.

**`context-aware-masking.Rmd`** — Masking context-aware: uso de límites administrativos y densidad poblacional para evitar relocalizaciones irreales.

**`reproducible-reporting.Rmd`** — Cómo documentar un análisis con `mask_report()` para publicación científica. Plantilla de sección "Métodos" para artículos.

### Sitio web pkgdown

Configurar `_pkgdown.yml` con:

- Navbar: Reference, Vignettes, News, GitHub.
- Agrupación de funciones por categoría (Masking, Privacy, Utility, Reporting).
- Tema visual coherente.
- Despliegue automático en GitHub Actions.

### README bilingüe

El `README.md` debe estar disponible en inglés (principal, en el repo) y en español (como sección adicional o archivo `README_ES.md`), dado el foco latinoamericano del proyecto.

---

## 8. Flujos de trabajo reproducibles

### Objeto de configuración `geomask_config`

Considerar una clase S3 `geomask_config` que encapsule parámetros de masking, semilla, y capa contextual, y pueda serializarse a YAML para reproducibilidad total:

```r
cfg <- geomask_config(
  method   = "donut",
  min_r    = 500,
  max_r    = 2000,
  seed     = 42,
  boundary = "path/to/comunas.gpkg"
)
# Guardar configuración
write_geomask_config(cfg, "masking_config.yml")
# Leer y aplicar
cfg2 <- read_geomask_config("masking_config.yml")
masked <- apply_mask(data, cfg2)
```

### Plantilla de reporte

Incluir una plantilla R Markdown (`geomask_report_template.Rmd`) que genere automáticamente:

- Resumen de parámetros
- Tabla de métricas de privacidad y utilidad
- Mapas comparativos
- Texto metodológico en prosa listo para insertar en un artículo

---

## 9. Difusión y construcción de comunidad

### Comunidades objetivo

- **rOpenSci**: proceso de revisión por pares, publicación en el ecosistema.
- **LatinR**: presentación del paquete (charla o póster).
- **SENTINET**: taller interno de uso con el equipo de datos.
- **Abre Tu Ciencia**: talleres abiertos en español.
- **ISP Chile** y **SEC Chile**: demostraciones con datos sensibles de salud y energía.

### Materiales de difusión a producir

**Materiales técnicos:**

- Sitio web pkgdown (EN)
- README bilingüe (EN/ES)
- 4 vignettes detalladas
- Cheatsheet en A4 (1 página) con las funciones principales y sus argumentos
- Casos de uso reproducibles con datos abiertos (Chile, LATAM)

**Materiales de comunidad:**

- Blog post en rOpenSci (inglés): motivación, diseño, estado del paquete
- Blog post o artículo en Abre Tu Ciencia (español): masking para investigadores de salud
- Presentación LatinR (15-20 min): metodología + demo en vivo
- Taller práctico (2-3 horas): para SENTINET/ATC, incluye casos de uso reproducibles

**Redes y visibilidad:**

- Repositorio GitHub con topics: `r`, `spatial`, `geomasking`, `privacy`, `epidemiology`, `ropensci`
- ORCID vinculado al paquete
- Zenodo DOI para cada release estable
- Mención en repositorios de herramientas epidemiológicas (R-epidemics, RECON)

### Estrategia de revisión rOpenSci

Ver sección 10.

---

## 10. Revisión rOpenSci

El proceso de revisión por pares de rOpenSci requiere:

1. **Pre-submission inquiry**: enviar resumen del paquete al editor de rOpenSci para verificar scope y fit antes de la submisión formal.
2. **Cumplimiento del rOpenSci guide**: revisar y cumplir todos los puntos del [rOpenSci Packages guide](https://devguide.ropensci.org/).
3. **Checklist de submisión**: `devtools::check()` limpio, cobertura de tests, vignettes, NEWS.md actualizado, DESCRIPTION completo.
4. **Respuesta a reviewers**: incorporar feedback de al menos 2 revisores en la PR de revisión.
5. **Badge rOpenSci**: incluir en README tras aprobación.

---

## 11. Checklist mensual (Junio 2025 – Abril 2027)

> Leyenda: `[ ]` pendiente · `[x]` completado · `[-]` parcialmente completado

---

### Junio 2025 — Fundamentos y estructura

- [ ] Completar `DESCRIPTION` con dependencias definitivas (`Imports`)
- [ ] Configurar `testthat` con `usethis::use_testthat()`
- [ ] Crear datasets sintéticos (`geomask_pts`, `geomask_boundary`) y scripts en `data-raw/`
- [ ] Implementar `mask_random_perturbation()` con documentación roxygen2 y tests básicos
- [ ] Configurar GitHub Actions: `R-CMD-check.yaml`
- [ ] Asegurar que `devtools::check()` pasa sin errores ni warnings en Linux

---

### Julio 2025 — Métodos de masking: donut y gaussiano

- [ ] Implementar `mask_donut()` con validación de `min_r < max_r`
- [ ] Implementar `mask_gaussian()` con manejo de CRS proyectado vs. geográfico
- [ ] Tests unitarios para ambas funciones (comportamiento correcto, casos borde, reproducibilidad)
- [ ] Verificar manejo de unidades con `units` package
- [ ] Primera versión del `README.md` en inglés con ejemplo básico
- [ ] Revisión con mentor(a) rOpenSci: feedback sobre diseño de API

---

### Agosto 2025 — Métodos avanzados: density-aware y aggregation

- [ ] Implementar `mask_density_displacement()` con integración de capa poblacional (`terra`)
- [ ] Implementar `mask_adaptive_aggregation()` con lógica de fusión de zonas
- [ ] Tests de integración con `terra` y `sf`
- [ ] Documentación detallada con referencias matemáticas en `@details`
- [ ] Actualizar README con listado completo de funciones disponibles

---

### Septiembre 2025 — Location swapping y context-aware

- [ ] Implementar `mask_location_swapping()` con restricciones contextuales
- [ ] Implementar `mask_context_aware()` con lógica de re-muestreo y zonas prohibidas
- [ ] Tests para `mask_context_aware()`: verificar que ningún punto cae fuera del límite
- [ ] Iniciar `vignette/intro-geomask.Rmd`
- [ ] Reunión de cohorte rOpenSci: presentar avance

---

### Octubre 2025 — Métricas de privacidad

- [ ] Implementar `privacy_k_anonymity()` con output por punto y global
- [ ] Implementar `privacy_disclosure_risk()` (método nearest-neighbor y probabilístico)
- [ ] Tests cuantitativos: verificar que el k-anonimato calculado coincide con valores esperados en datasets sintéticos controlados
- [ ] Vignette `privacy-utility-tradeoff.Rmd`: primera versión
- [ ] Publicar blog post interno en Abre Tu Ciencia sobre geomasking (divulgación temprana)

---

### Noviembre 2025 — Métricas de utilidad: estadísticas espaciales

- [ ] Implementar `utility_spatial_stats()` con NND y K de Ripley
- [ ] Tests de comparación: verificar que $\Delta K \approx 0$ cuando `max_r = 0` (sin masking)
- [ ] Integración con `spdep` y `spatstat`
- [ ] Completar vignette `privacy-utility-tradeoff.Rmd`
- [ ] Configurar `pkgdown` básico y despliegue automático

---

### Diciembre 2025 — Métricas de utilidad: clusters y epidemiología

- [ ] Implementar `utility_cluster_detection()` con Moran global y local
- [ ] Implementar `utility_epi_summary()` con tasas por zona y distancias a servicios
- [ ] Implementar `utility_summary()` como función envolvente
- [ ] Tests de regresión: guardar snapshots de resultados esperados con `testthat::expect_snapshot()`
- [ ] Revisión intermedia con mentor(a): evaluación de cobertura de tests y API

---

### Enero 2026 — Reporte reproducible y objeto de configuración

- [ ] Implementar `mask_report()` con output estructurado
- [ ] Diseñar y documentar clase S3 `geomask_config`
- [ ] Implementar `write_geomask_config()` y `read_geomask_config()` (YAML)
- [ ] Crear plantilla R Markdown de reporte (`geomask_report_template.Rmd`)
- [ ] Vignette `reproducible-reporting.Rmd`: primera versión completa
- [ ] Cobertura de tests ≥ 80%

---

### Febrero 2026 — Vignettes y documentación completa

- [ ] Completar las 4 vignettes
- [ ] Revisar toda la documentación roxygen2: completar `@examples`, `@references`, `@seealso`
- [ ] Añadir `@references` con literatura clave (Kwan 2004, Allshouse 2010, Cassa 2008, etc.)
- [ ] Vignette context-aware: caso de uso con datos Chile
- [ ] Primera versión del sitio pkgdown completo
- [ ] README bilingüe (EN + sección ES)

---

### Marzo 2026 — Preparación para pre-submission rOpenSci

- [ ] `devtools::check()` limpio en Ubuntu, macOS, Windows
- [ ] Cobertura de tests ≥ 90%
- [ ] Revisar checklist rOpenSci Packages guide
- [ ] Enviar pre-submission inquiry a rOpenSci
- [ ] Preparar presentación para LatinR 2026 (abstract + slides)
- [ ] Cheatsheet v1: diseño y contenido

---

### Abril 2026 — Submisión rOpenSci y LatinR

- [ ] Responder feedback del pre-submission inquiry
- [ ] Submisión formal a rOpenSci (abrir issue en `ropensci/software-review`)
- [ ] Presentación en LatinR 2026
- [ ] Publicar blog post en rOpenSci (borrador)
- [ ] Taller en SENTINET: flujos reproducibles con `geomask`

---

### Mayo 2026 — Proceso de revisión rOpenSci (Ronda 1)

- [ ] Responder comentarios de reviewer 1
- [ ] Responder comentarios de reviewer 2
- [ ] Actualizar código, tests y documentación según feedback
- [ ] Publicar blog post Abre Tu Ciencia: "geomasking para ciencias sociales" (ES)
- [ ] Actualizar NEWS.md con cambios de la ronda de revisión

---

### Junio 2026 — Proceso de revisión rOpenSci (Ronda 2) + materiales

- [ ] Incorporar revisiones finales
- [ ] Re-run de todos los checks en 3 plataformas
- [ ] Preparar demo para ISP Chile (datos sensibles de salud)
- [ ] Cheatsheet v2: final, publicada en el sitio pkgdown
- [ ] Zenodo DOI para release candidato

---

### Julio 2026 — Aprobación rOpenSci y release v0.1.0

- [ ] Aprobación por editor rOpenSci
- [ ] Badge rOpenSci en README
- [ ] Release v0.1.0 en GitHub con tag y release notes
- [ ] Zenodo DOI estable para v0.1.0
- [ ] CRAN submission (si se alcanza el estándar) o preparación para CRAN
- [ ] Anuncio en rOpenSci community forum y redes

---

### Agosto 2026 — Casos de uso aplicados (LATAM)

- [ ] Caso de uso 1: datos de vigilancia epidemiológica (ISP Chile) — documento reproducible
- [ ] Caso de uso 2: datos de distribución de infraestructura sensible (SEC Chile)
- [ ] Publicar ambos casos en el sitio pkgdown como artículos adicionales
- [ ] Reunión con Abre Tu Ciencia: taller abierto (2-3 hs) con materiales descargables

---

### Septiembre 2026 — Internacionalización y CRAN

- [ ] Completar tramitación CRAN (si no completada en julio)
- [ ] Traducir README, vignette principal y cheatsheet al inglés con revisión nativa
- [ ] Añadir `geomask` a CRAN Task View: Spatial, Epidemiology
- [ ] Contactar con RECON (R Epidemics Consortium) para inclusión en recursos recomendados
- [ ] Identificar potenciales colaboradores internacionales (GitHub issues, Twitter/Mastodon)

---

### Octubre 2026 — Extensiones: métodos adicionales

- [ ] Evaluar implementación de métodos adicionales: voronoi masking, kernel-based masking
- [ ] Abrir issues de discusión en GitHub para priorizar extensiones
- [ ] Actualizar roadmap del paquete en README
- [ ] Presentación en congreso regional o internacional (abstract enviado)

---

### Noviembre 2026 — Artículo de software

- [ ] Redactar artículo de software para Journal of Open Source Software (JOSS) o R Journal
- [ ] Incluir benchmarks, comparación con métodos ad-hoc existentes, casos de uso
- [ ] Revisión interna del borrador con co-autores/colaboradores
- [ ] Enviar preprint a arXiv o SocArXiv

---

### Diciembre 2026 — Revisión de artículo y mantenimiento

- [ ] Responder revisores del artículo de software
- [ ] Release v0.2.0 con mejoras acumuladas desde v0.1.0
- [ ] Revisar y actualizar dependencias (versiones nuevas de `sf`, `terra`)
- [ ] Actualizar vignettes con nuevas funcionalidades
- [ ] Sesión de retrospectiva: balance del año, ajuste del plan

---

### Enero 2027 — Estabilización y documentación avanzada

- [ ] Artículo de software: revisión final y correcciones
- [ ] Vignette avanzada: análisis de sensibilidad de parámetros (radio, k, sigma)
- [ ] Añadir soporte para múltiples CRS en todas las funciones
- [ ] Resolver issues abiertos de la comunidad en GitHub
- [ ] Taller Abre Tu Ciencia 2027: actualización con nuevas funciones

---

### Febrero 2027 — Documentación de cierre y comunidad

- [ ] Aceptación del artículo de software (objetivo)
- [ ] Manual de referencia completo (pkgdown Reference page)
- [ ] Guía de contribución actualizada (CONTRIBUTING.md)
- [ ] Plantilla de issue y PR en `.github/`
- [ ] Estadísticas de uso: descargas CRAN, citaciones, forks

---

### Marzo 2027 — Release v1.0.0

- [ ] Release v1.0.0: API estable, todos los métodos planificados implementados
- [ ] Anuncio en rOpenSci community forum, LatinR Slack, R-ladies, y redes
- [ ] Presentación de cierre del ciclo rOpenSci Champions
- [ ] Publicar post de balance en Abre Tu Ciencia: lecciones aprendidas
- [ ] Transferir aprendizajes al equipo SENTINET (sesión de cierre)

---

### Abril 2027 — Cierre del programa y proyección futura

- [ ] Publicación del artículo de software (si no completado antes)
- [ ] Reporte final para rOpenSci Champions Program
- [ ] Plan de mantenimiento a largo plazo (releases semestrales, triage de issues)
- [ ] Identificar posibles contribuidores para mantener el paquete activo
- [ ] Documentar lecciones aprendidas sobre desarrollo de paquetes en contexto latinoamericano
- [ ] **Meta final**: `geomask` en CRAN, revisado por rOpenSci, con artículo de software publicado, sitio web activo, comunidad de usuarios hispanohablantes y anglohablantes establecida.

---

## Referencias metodológicas clave

- Kwan, M.-P., Casas, I., & Schmitz, B. C. (2004). Protection of geoprivacy and accuracy of spatial information: How effective are geographical masks? *Cartographica*, 39(2), 15–28.
- Allshouse, W. B., Fitch, M. K., Hampton, K. H., Gesink, D. C., Doherty, I. A., Leone, P. A., ... & Emch, M. (2010). Geomasking sensitive health data and privacy protection. *Spatial and Spatio-temporal Epidemiology*, 1(2-3), 101–110.
- Cassa, C. A., Grannis, S. J., Overhage, J. M., & Mandl, K. D. (2006). A context-sensitive approach to anonymizing spatial surveillance data. *Journal of the American Medical Informatics Association*, 13(2), 160–165.
- Sweeney, L. (2002). k-anonymity: A model for protecting privacy. *International Journal of Uncertainty, Fuzziness and Knowledge-Based Systems*, 10(05), 557–570.
- Wiggins, D. L., Schmidt-Ott, R., O'Sullivan, D., Lowe, D. J., Alam, S., Perez, G., & Reyna, A. (2022). Geomasking revisited: a review of techniques for protecting individual location privacy in health research. *ISPRS International Journal of Geo-Information*, 11(7), 384.

---

*Documento generado: Junio 2025. Revisión programada: cada 3 meses o tras hito mayor.*
