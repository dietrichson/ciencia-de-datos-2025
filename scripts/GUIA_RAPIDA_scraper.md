# Guía Rápida - Scraper de Metacritic

## Inicio Rápido (5 minutos)

### 1. Instalar Paquetes (solo la primera vez)

```r
install.packages(c("httr2", "xml2", "rvest", "tidyverse"))
```

### 2. Ejecutar Ejemplo Completo

```r
# Cargar el script
source("scripts/scrape_metacritic_albums.R")

# Ejecutar ejemplo (hace todo automáticamente)
run_example()
```

¡Listo! Los datos se guardarán en `data/metacritic_albums.csv`

---

## Comandos Más Usados

### Scraping Básico

```r
# Extraer álbumes de la primera página
albums <- scrape_metacritic_albums()

# Ver los datos
View(albums)
glimpse(albums)
```

### Scraping de Múltiples Páginas

```r
# Extraer 3 páginas (aproximadamente 60 álbumes)
albums <- scrape_multiple_pages(pages = 0:2, delay = 3)
```

### Guardar Datos

```r
# Guardar en CSV
save_albums_to_csv(albums, filename = "mis_albums.csv")

# O con tidyverse
library(tidyverse)
albums %>% write_csv("data/mis_albums.csv")
```

---

## Análisis Rápido

### Top 10 Álbumes

```r
library(tidyverse)

# Mejor puntuados por críticos
albums %>%
  filter(!is.na(metascore)) %>%
  arrange(desc(metascore)) %>%
  select(album_title, artist_name, metascore) %>%
  head(10)
```

### Estadísticas Básicas

```r
albums %>%
  summarize(
    total = n(),
    promedio_criticos = mean(metascore, na.rm = TRUE),
    promedio_usuarios = mean(user_score, na.rm = TRUE)
  )
```

### Visualización Simple

```r
library(ggplot2)

# Histograma de puntuaciones
albums %>%
  filter(!is.na(metascore)) %>%
  ggplot(aes(x = metascore)) +
  geom_histogram(bins = 20, fill = "steelblue") +
  theme_minimal() +
  labs(title = "Distribución de Metascores",
       x = "Metascore", y = "Cantidad")
```

---

## Verificar que Funciona

```r
# Ejecutar tests
source("scripts/test_metacritic_scraper.R")
```

Si todos los tests pasan (✓), el scraper está funcionando correctamente.

---

## Solución de Problemas Rápida

### Error: "could not find function"
**Solución**: Cargar el script primero
```r
source("scripts/scrape_metacritic_albums.R")
```

### Error: "no package called 'httr2'"
**Solución**: Instalar paquetes
```r
install.packages(c("httr2", "xml2", "rvest", "tidyverse"))
```

### Advertencia: "No album entries found"
**Solución**: Puede ser temporal, esperar unos minutos y reintentar

---

## Datos Extraídos

Cada fila representa un álbum con:

- `album_title`: Título del álbum
- `artist_name`: Nombre del artista
- `metascore`: Puntuación críticos (0-100)
- `user_score`: Puntuación usuarios (0-10)
- `release_date`: Fecha de lanzamiento
- `summary`: Descripción
- `album_url`: Link al álbum
- `cover_image_url`: Link a la imagen
- `scraped_at`: Cuándo se extrajo

---

## Buenas Prácticas

✓ **Usar delays**: `delay = 2` o más para ser respetuoso
✓ **No abusar**: Máximo 5-10 páginas por sesión
✓ **Guardar regularmente**: Usar `save_albums_to_csv()` frecuentemente
✓ **Verificar datos**: Revisar con `glimpse()` y `summary()`

❌ **No hacer**: Scraping masivo o automatizado frecuente
❌ **No hacer**: Usar delays menores a 1 segundo
❌ **No hacer**: Publicar datos sin atribución

---

## Recursos

- **README completo**: `scripts/README_scraper.md`
- **Script principal**: `scripts/scrape_metacritic_albums.R`
- **Tests**: `scripts/test_metacritic_scraper.R`

---

## Ejemplo Completo de Flujo de Trabajo

```r
# 1. Cargar librerías y script
library(tidyverse)
source("scripts/scrape_metacritic_albums.R")

# 2. Extraer datos
albums <- scrape_metacritic_albums(delay = 3, verbose = TRUE)

# 3. Explorar
glimpse(albums)
summary(albums)

# 4. Analizar
top_albums <- albums %>%
  filter(!is.na(metascore)) %>%
  arrange(desc(metascore)) %>%
  head(10)

# 5. Visualizar
library(ggplot2)
albums %>%
  filter(!is.na(metascore)) %>%
  ggplot(aes(x = metascore)) +
  geom_histogram(bins = 20, fill = "coral") +
  theme_minimal()

# 6. Guardar
save_albums_to_csv(albums, filename = "albums_analisis.csv")
```

---

**¿Preguntas?** Consulta el README completo o contacta al instructor del seminario.
