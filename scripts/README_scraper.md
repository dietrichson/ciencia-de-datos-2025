# Metacritic Album Scraper - Guía de Uso

## Descripción General

Este script de R permite extraer datos de álbumes musicales desde Metacritic de manera automatizada y respetuosa con el sitio web. Incluye manejo de errores, limitación de velocidad (rate limiting), y funciones para exportar datos.

## Requisitos Previos

### Instalación de Paquetes

```r
# Instalar paquetes necesarios
install.packages(c("httr2", "xml2", "rvest", "tidyverse"))
```

### Paquetes Utilizados

- **httr2**: Peticiones HTTP modernas y seguras
- **xml2**: Parsing de documentos HTML/XML
- **rvest**: Web scraping simplificado
- **tidyverse**: Manipulación y análisis de datos

## Uso Básico

### 1. Ejecutar el Ejemplo Completo

La forma más sencilla de probar el scraper:

```r
# Cargar el script
source("scripts/scrape_metacritic_albums.R")

# Ejecutar ejemplo que incluye:
# - Scraping de primera página
# - Resumen de datos
# - Guardado automático en CSV
run_example()
```

### 2. Scraping de Una Página

```r
# Scraping básico
albums <- scrape_metacritic_albums()

# Ver los datos
glimpse(albums)
head(albums)
```

### 3. Scraping con Configuración Personalizada

```r
# URL personalizada y mayor delay
albums <- scrape_metacritic_albums(
  url = "https://www.metacritic.com/browse/albums/release-date/new-releases/date?view=detailed",
  delay = 3,      # 3 segundos entre peticiones
  verbose = TRUE  # Mostrar mensajes de progreso
)
```

### 4. Scraping de Múltiples Páginas

```r
# Extraer las primeras 5 páginas
albums_multiple <- scrape_multiple_pages(
  pages = 0:4,    # Páginas 0-4
  delay = 3,      # 3 segundos entre peticiones
  verbose = TRUE
)

# Ver estadísticas
cat(sprintf("Total de álbumes: %d\n", nrow(albums_multiple)))
cat(sprintf("Álbumes únicos: %d\n", n_distinct(albums_multiple$album_url)))
```

### 5. Guardar Datos

```r
# Guardar en CSV con nombre personalizado
save_albums_to_csv(
  albums_df = albums,
  filename = "albums_octubre_2025.csv",
  path = "data"
)

# O usar tidyverse directamente
albums %>%
  write_csv("data/mi_archivo.csv")
```

## Estructura de Datos

El scraper retorna un tibble con las siguientes columnas:

| Columna | Tipo | Descripción | Ejemplo |
|---------|------|-------------|---------|
| `album_title` | character | Título del álbum | "The Rise and Fall of a Midwest Princess" |
| `artist_name` | character | Nombre del artista | "Chappell Roan" |
| `metascore` | numeric | Puntuación de críticos (0-100) | 85 |
| `user_score` | numeric | Puntuación de usuarios (0-10) | 8.7 |
| `release_date` | character | Fecha de lanzamiento | "Sep 22, 2023" |
| `summary` | character | Descripción del álbum | "The debut album..." |
| `album_url` | character | URL completa del álbum | "https://www.metacritic.com/music/..." |
| `cover_image_url` | character | URL de la imagen de portada | "https://static.metacritic.com/..." |
| `scraped_at` | POSIXct | Timestamp de cuándo se extrajo | "2025-10-28 18:30:45" |

### Valores Faltantes

- Los campos pueden contener `NA` si la información no está disponible
- Los "tbd" (to be determined) se convierten automáticamente a `NA`
- Las puntuaciones de usuario frecuentemente están ausentes para lanzamientos recientes

## Análisis de Datos - Ejemplos

### Estadísticas Básicas

```r
library(tidyverse)

# Resumen de puntuaciones
albums %>%
  summarize(
    n_albums = n(),
    avg_metascore = mean(metascore, na.rm = TRUE),
    avg_user_score = mean(user_score, na.rm = TRUE),
    max_metascore = max(metascore, na.rm = TRUE),
    albums_with_user_scores = sum(!is.na(user_score))
  )
```

### Top 10 Álbumes por Metascore

```r
albums %>%
  filter(!is.na(metascore)) %>%
  arrange(desc(metascore)) %>%
  select(album_title, artist_name, metascore, user_score) %>%
  head(10)
```

### Comparación Críticos vs Usuarios

```r
# Álbumes con ambas puntuaciones
albums_compared <- albums %>%
  filter(!is.na(metascore) & !is.na(user_score)) %>%
  mutate(
    # Normalizar metascore a escala 0-10
    metascore_normalized = metascore / 10,
    difference = user_score - metascore_normalized
  )

# Álbumes donde usuarios y críticos difieren más
albums_compared %>%
  arrange(desc(abs(difference))) %>%
  select(album_title, artist_name, metascore, user_score, difference) %>%
  head(10)
```

### Visualización

```r
library(ggplot2)

# Distribución de Metascores
albums %>%
  filter(!is.na(metascore)) %>%
  ggplot(aes(x = metascore)) +
  geom_histogram(bins = 20, fill = "steelblue", alpha = 0.7) +
  theme_minimal() +
  labs(
    title = "Distribución de Metascores de Álbumes Nuevos",
    x = "Metascore (0-100)",
    y = "Número de Álbumes"
  )

# Críticos vs Usuarios (scatter plot)
albums %>%
  filter(!is.na(metascore) & !is.na(user_score)) %>%
  ggplot(aes(x = metascore/10, y = user_score)) +
  geom_point(alpha = 0.6, size = 3, color = "coral") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray40") +
  theme_minimal() +
  labs(
    title = "Metascore vs User Score",
    x = "Metascore (normalizado 0-10)",
    y = "User Score (0-10)"
  ) +
  coord_fixed()
```

## Buenas Prácticas

### 1. Respetar el Sitio Web

```r
# Usar delays apropiados (2-5 segundos)
albums <- scrape_metacritic_albums(delay = 3)

# No hacer scraping excesivo
# Limitar a 5-10 páginas máximo por sesión
albums <- scrape_multiple_pages(pages = 0:4, delay = 3)
```

### 2. Manejo de Errores

```r
# Usar tryCatch para robustez
safe_scrape <- function() {
  tryCatch({
    albums <- scrape_metacritic_albums()
    return(albums)
  }, error = function(e) {
    message("Error al hacer scraping: ", e$message)
    return(NULL)
  })
}

albums <- safe_scrape()
if (!is.null(albums)) {
  save_albums_to_csv(albums)
}
```

### 3. Guardar Datos Regularmente

```r
# Incluir fecha en el nombre del archivo
fecha <- format(Sys.Date(), "%Y-%m-%d")
filename <- sprintf("metacritic_albums_%s.csv", fecha)

albums <- scrape_metacritic_albums()
save_albums_to_csv(albums, filename = filename)
```

### 4. Verificar Datos

```r
# Verificar que los datos sean razonables
verify_data <- function(df) {
  checks <- list(
    has_rows = nrow(df) > 0,
    has_titles = sum(!is.na(df$album_title)) > 0,
    scores_valid = all(df$metascore[!is.na(df$metascore)] >= 0 &
                       df$metascore[!is.na(df$metascore)] <= 100)
  )

  if (all(unlist(checks))) {
    message("✓ Datos verificados correctamente")
  } else {
    warning("⚠ Problemas detectados en los datos")
  }

  return(checks)
}

verify_data(albums)
```

## Solución de Problemas

### Error: "HTTP request failed"

**Causa**: Problema de conexión o sitio web inaccesible

**Solución**:
```r
# Verificar conexión a internet
# Aumentar timeout
scrape_metacritic_albums(delay = 5)
```

### Warning: "No album entries found"

**Causa**: Estructura del HTML cambió o página incorrecta

**Solución**:
```r
# Verificar la URL manualmente en el navegador
# El sitio puede haber cambiado su estructura
# Contactar al mantenedor del script
```

### Muchos valores NA

**Causa**: Normal para algunos campos (especialmente user_score)

**Solución**:
```r
# Filtrar datos completos si es necesario
albums_complete <- albums %>%
  filter(!is.na(metascore) & !is.na(user_score))
```

## Limitaciones y Consideraciones

1. **Estructura del Sitio**: El scraper depende de la estructura HTML actual de Metacritic. Si el sitio cambia su diseño, el scraper necesitará actualizaciones.

2. **Rate Limiting**: El script incluye delays para ser respetuoso, pero scraping excesivo puede resultar en bloqueo temporal de IP.

3. **Datos Incompletos**: No todos los álbumes tienen user scores disponibles, especialmente los recién lanzados.

4. **Términos de Servicio**: Revise los términos de servicio de Metacritic antes de usar este scraper en producción.

5. **Uso Educativo**: Este script está diseñado para propósitos educativos en el contexto del seminario de ciencia de datos.

## Recursos Adicionales

### Documentación de Paquetes

- [httr2](https://httr2.r-lib.org/)
- [rvest](https://rvest.tidyverse.org/)
- [tidyverse](https://www.tidyverse.org/)

### Web Scraping en R

- [Wickham, H. & Grolemund, G. - R for Data Science](https://r4ds.had.co.nz/)
- [rvest tutorial](https://rvest.tidyverse.org/articles/rvest.html)

## Licencia y Uso

Este script es para uso educativo en el Seminario de Ciencia de Datos de UNSAM. Los datos extraídos pertenecen a Metacritic y están sujetos a sus términos de servicio.

## Autor

Seminario de Ciencia de Datos - UNSAM 2025
