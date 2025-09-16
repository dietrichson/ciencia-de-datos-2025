library(dplyr)
poner_genero <- function(mis_datos){
  mis_datos |> 
    rename(sexo=CH04) |> 
    mutate(sexo = ifelse(sexo==1,"Hombre","Mujer"))
}
