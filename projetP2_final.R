library(igraph)
library(influenceR)

setwd("~/Cours EISTI/ING3/Network linking/Projet")

#Modularit� locale R
mod_R <- function (g,C,B,S){
  bin <- length(E(g) [B%--%B]) #car on ne sait pas lequel est inf�rieur ou sup�rieur (graphe non dirig�)
  bout <- length(E(g)[B%--%S])
  return (bin/(bin+bout))
}

# B %->% S est un lien orient� de B vers S
# B %<-% S est un lien orient� de S vers B
# B %--% S quand on ne connait pas la direction, mais pour former un lien

#modularit� locale M = Din / Dout avec D = BUC
mod_M <- function (g,C,B,S) {
  D <- union (C,B)
  din <- length(E(g)[D%--%D])
  dout <- length(E(g)[B%--%S])
  return (din/dout)
}

#Calcul modularit� locale L
neighbors_in <- function (n,g,E){
  return (length(intersect(neighbors(g,n),E)))
}

mod_L <- function (g,C,B,S){
  D <- union(C,B)
  #sapply applique a chaque element de D la fonction neighbors in avec comme parametre g et (D ou S) 
  lin <- sum(sapply(D,neighbors_in,g,D))/length(D)
  lout <- sum(sapply(B,neighbors_in,g,S))/length(B)
  return (lin/lout)
}


#Fonction de mise � jour des C, B et S
update <- function(g, n, C, B, S){
  S <- S[S!=n] #on enleve le noeud de S
  D <- union(C,B)   # D = C+B
  if (all(neighbors(g, n) %in% D)){ #si tous les voisins de n sont dans D alors
    #on rajoute n � C
    C <- union(C, n)
  }
  else{ # si il a des voisins � l'exterieur de D
    #on rajoute n � B
    B <- union(B, n)
    new_s = setdiff(neighbors(g, n), union(D,S)) #on met a jour les modifs sur le graphe
    if (length(new_s)>0) #s'il y a encore des noeuds dans S
    {
      S <- V(g)[V(g)$id %in% union(S$id, new_s)] #on met a jour S sans le noeud trait�
    }
    for (b in B) #pour tous les noeuds dans B
    {
      if (all(neighbors(g, n) %in% D)){  #si le noeud a des voisins dans D alors
        B <- B[B!=b] #on l'enl�ve de B
        C <- union(C, b) #on l'ajoute � C
      }
    }
  }
  return (list(C=C,B=B,S=S)) #on renvoie les ensembles ainsi constitu�
}

#Fonction de qualit�
qualite <- function(g, n, C, B, S, mod)
{
  res <- update(g, n, C, B, S)
  C <- res$C
  B <- res$B
  S <- res$S
  return (mod(g, C, B, S)) #on retourne la modularit� R ou M ou L choisie
}


#Fonction de d�tection des communaut�s
local_com <- function(g, target, modularite)
{
  if (is.igraph(g) && target %in% V(g)){ #on s'assure que g est un graphe et que le noeud cible est dans le graphe g
    #initialisation
    C <- c() #C est un vecteur vide
    B <- c(target) #B ne contient que le noeud "cible"
    S <- neighbors(g, target) #S contient les voisins du noeud cible 
    Q0 <- 0 #la fonction de qualit� est nulle
    Q1 <- 100000000 #pour condition de convergence
    
    while ((Q1>Q0) && (length(S)>0)) #tant qu'il reste des noeuds dans S et que la qualit� est toujours sup�rieure � l'ancienne (elle s'am�liore) alors
    {
      l <- c()
      for (n in S) #pour chaque noeud dans S
      {
        mod <- qualite(g, n, C, B, S, modularite) #on calcule sa modularit�
        l <- c(l, mod) #l = vecteur contenant les modularit�s
      }
      Q1 <- max(l) #Q1 re�oit le maximun des modularit�s calcul�es
      if (Q1 > Q0){ #si cette qualit� est meilleure que l'ancienne
        n_move <- S[which.max(l)] #on trouve le noeud a bouger (celui dont la modularit� est la plus �lev�e)
        res <- update(g, n_move, C, B, S) #mise � jour du graphe
        C <- res$C #mise � jour des ensembles C, B et S et de Q0 et Q1
        B <- res$B
        S <- res$S
        Q0 <- Q1
        Q1 <- Q1+1
      }
    }
    return (union(B,C))
  }
  else{
    stop("invalid arguments")
  }
}


#LECTURE DU CSV ET CREATION DU GRAPHE , TRANSFORMATION EN GRAPHE BIPARTITE

data <- read.csv(file = 'data.csv',header = TRUE)
g <- graph.data.frame(data, directed = FALSE)
V(g)$type <- V(g)$name %in% data[,2] #the second column of edges is TRUE type
E(g)$weight <- as.numeric(data[,3])
g
is.bipartite(g)

# PLOT GRAPH

V(g)$color <- V(g)$type
V(g)$color=gsub("FALSE","red",V(g)$color)
V(g)$color=gsub("TRUE","blue",V(g)$color)
plot(g, edge.color="gray30",edge.width=E(g)$weight, layout=layout_as_bipartite)

# PROJECTION
proj <-bipartite_projection(g)
proj$proj1 #=> graphique projet� des utilisateurs
proj$proj2 #=> graphique projet� des films

plot(proj$proj1, vertex.label=NA, main="Graphe projet� des utilisateurs")
plot(proj$proj2, vertex.label=NA, main="Graphe projet� des films")

#FONCTIONS DE DETECTION DES COMMUNAUTES ET RECOMMANDATION


filmsMieuxNotes <- function(g,data) { #garde les films les mieux not�s par la communaut� (note moyenne > 3)
  listeFilms <-unique(data$title) #on prend tous les films (unique)
  bonsFilms <- rep(0, length(listeFilms)) #on va stocker ici les bons films
  for (i in (1:length(listeFilms))){
    note <- mean(E(g)$weight[V(g)$name ==listeFilms[i]]) #on calcule la moyenne de leurs notes donn�es par les utilisateurs
    if (note > 3) { #si la moyenne est superieure a 3
      bonsFilms[i] = listeFilms[i] #on ajoute le film a la liste des films a proposer
    }
  }
  return (bonsFilms)
}

meilleursFilms <- filmsMieuxNotes(g,data)

trouveNoteGlobale <- function(g,film) { #trouve la note globale d'un film entr� pour tous les utilisateurs du graphe
  notes <- E(g)$weight[V(g)$name ==film]
  moyNotes <- mean(notes)
  return(moyNotes)
}

trouveNoteCommunaute <- function(com) { #trouve la note donn�e par la communaut� s�lectionn�e pour un film donn�
  notes <- E(com)$weight
  moyNotes <- mean(notes)
  return(moyNotes)
}

recupereNoteCommunaute <- function(g,com_graph,film) { #r�cup�re les notes de la communaut� locale induite
  noeuds <- V(com_graph)
  res <- rep(0, length(noeuds)+1)
  for (i in (1:length(noeuds))) {
    res[i] = noeuds[i]
  }
  res[length(res)] = film
  resGraph <- induced.subgraph(g,res)
  return (resGraph)
}

trouveCommunauteFilm <- function(data,film) { #r�cup�re les user qui ont vu le film mis en param�tre
  list_user <- data$userId[data$title == film]
  return (list_user)
}

trouveCommunauteUser <- function(data,user) { #r�cup�re les films qui ont �t� vu par le user mis en param�tre
  list_film <- data$title[data$userId == user]
  return (list_film)
}

trouveFilmsCommuns <- function(data,user) { #r�cup�re les user qui ont vu 5 films communs avec le user en param�tre
  liste_film_1 <- trouveCommunauteUser(data,user)
  inter <- trouveCommunauteFilm(data,liste_film_1[1])
  for (film in (1:5)) { #personne qui ont vu 5 films en communs (si l'on met(1:length(liste_film1)) renvoie 0 car personne n'a vu exactement tous les films d'un user)
    listeUser <- trouveCommunauteFilm(data,liste_film_1[film])
    inter <-Reduce(intersect,  list(listeUser,inter))
  }
  return (inter)
} 


main <- function(data,g,user,film) {
  comLocale = local_com(proj$proj1, user, mod_L) #modularit� qui donne les meilleurs r�sultats
  com_graph = induced.subgraph(proj$proj1, comLocale) #graphe de la communaut� locale du user cr��e
  #calcul de la note pour la communaut� locale pour l'utilisateur
  comNoeud_Notes <- recupereNoteCommunaute(g,com_graph,film) #on r�cup�re les notes (weight) de la communaut� locale trouv�e
  noteComUser <- trouveNoteCommunaute(comNoeud_Notes) #on calcule la note attribu�e au film selectionn� par les utilisateurs de la communaut� du noeud consid�r� (communaut� user consid�r�)
  #calcul de la note pour la communaut� locale du film
  user_communs <- trouveFilmsCommuns(data,user) #on cherche tous les user qui ont vu 5 films communs avec l'user entr�
  user_communs_graph <- induced.subgraph(g, user_communs) #on applique le graphe
  comNoeud_Notes_films <- recupereNoteCommunaute(g,user_communs_graph,film) #on r�cup�re les notes (weight) de la communaut� locale trouv�e
  noteComFilm <- trouveNoteCommunaute(comNoeud_Notes_films) #on calcule la note attribu�e au film selectionn� par les utilisateurs ayant 5 films communs (communaut� film consid�r�)
  #calcul de la note globale du film
  noteGlobaleFilm <- trouveNoteGlobale(g,film)
  print("The global scoring for the movie is :")
  print(noteGlobaleFilm)
  print("The scoring given by the user community is :")
  print(noteComUser)
  print("The scoring given by the movie community is : ")
  print(noteComFilm)
}

main(data,g,1,"Toy Story (1995)")

main(data,g,1,"Grumpier Old Men (1995)")

main(data,g,5,"Batman (1989)")
