# ============================
# Trabajo con student-dataset.csv
# ============================

# Cargar librerías
library(dplyr)
library(ggplot2)
library(readr)

# 1. Importar datos
my_data <- read_csv("student-dataset.csv")

# 2. Renombrar columnas al español
mis_datos <- my_data |> 
  rename(
    id = ID,
    nombre = Name,
    sexo = Gender,
    edad = Age,
    peso_kg = Weight_kg,
    altura_cm = Height_cm,
    bebida_preferida = Preferred_Beverage,
    tamano_hogar = Household_Size
  )

# 3. Transformar variables nominales al castellano
mis_datos <- mis_datos |> 
  transform(
    sexo = ifelse(sexo == "Female", "Mujer", "Hombre"),
    bebida_preferida = case_when(
      bebida_preferida == "Coffee" ~ "Café",
      bebida_preferida == "Tea" ~ "Té",
      bebida_preferida == "Mate" ~ "Mate"
    )
  )

# 4. Medidas de centralización y dispersión para la edad
media_edad <- mean(mis_datos$edad)
mediana_edad <- median(mis_datos$edad)
desv_edad <- sd(mis_datos$edad)
mad_edad <- mad(mis_datos$edad)

cat("Media de edad:", media_edad, "\n")
cat("Mediana de edad:", mediana_edad, "\n")
cat("Desviación estándar:", desv_edad, "\n")
cat("Desviación absoluta media:", mad_edad, "\n\n")

# 5. Frecuencias de variables nominales
cat("Distribución por sexo:\n")
print(table(mis_datos$sexo))

cat("\nDistribución por bebida preferida:\n")
print(table(mis_datos$bebida_preferida))

# 6. Visualización de una variable (ejemplo: edades)
ggplot(mis_datos, aes(x = edad)) +
  geom_histogram(binwidth = 1, fill = "skyblue", color = "black") +
  labs(title = "Distribución de edades", x = "Edad", y = "Frecuencia")

# 7. Visualización de variable categórica (sexo)
ggplot(mis_datos, aes(x = sexo, fill = sexo)) +
  geom_bar() +
  labs(title = "Distribución por sexo", x = "Sexo", y = "Frecuencia") +
  theme_minimal()
