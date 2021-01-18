# GraphTheory_MovieRecommandation

Score attribution for a couple (user,movie) using graph theory with R

# Objective

The goal of the project is to predict a rating for a couple (user, movie) based on the ratings assigned by their respective local communities (defined below in "project realisation" section).

This project allows you to train on:
- the recommendation
- the R language
- graph theory

# Graph Theory 

Abstractly, a graph is the data of a certain number of points on the plane, called nodes or vertices, some of which are connected by segments of lines or curves called edges. The number of vertices in the graph is its order. If we name X the set of vertices and U the set of edges, a graph G can be written G = (X, U).

# Dataset

The dataset comes from MovieLens site collected by the GroupLens research project at the University of Minnesota.

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/CSV%20head.png?raw=true)

This dataset is composed of 3 columns :
- UserId : one number id for each user
- MovieId : one number id for each movie
- Ratings : the rating (up to 5) given by a user to a movie

# Project realisation

First, we have to transform the csv to a graph. Users and movies are represented by nodes. If a user have seen a movie, the two nodes are linked by edges. The weight of that edge is the rating given by that user to that movie.

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/GraphG.png?raw=true)

Then, we have to transform this graph to a bipartite graph. A bipartite graph (or bigraph) is a graph whose vertices can be divided into two disjoint and independent sets U and V such that every edge connects a vertex in U to one in V.


![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/graph_bi.PNG?raw=true)

In our case, here is the transformation of our graph :

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/graph_bi_.PNG?raw=true)

The blue vertices are the movies and the red ones are the users, linked by edges.

We have then to project this bipartite graph to detect the local communities of each group of nodes. Biparty graph projection is a widely used method of "compressing" the information contained in the graph. We also note that the projection artificially increases the clustering coefficient of the projected graph.

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/projection_ex.PNG?raw=true)

Here is the user graph projection :

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/proj_users.png?raw=true)

And the movie graph projection :

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/proj_films.PNG?raw=true)

To predict those ratings for each couple (user, movie), we are going to find their respective local community. A community is defined in relation to a current graph as a group of nodes which are particularly linked to each other and weakly linked to the rest of the network. It may be, for example, individuals who exchange a lot with each other and little with others. In the world, this materializes in social networks: the friends of the same circle all know each other, but there is a big separation between two different circles.

To detect the community, we will use the L modularity. 

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/modularity.png?raw=true)

To illustrate the algorithm, we will take an example of a local community. Here node C represents our local community, node B its border and S the edges of our community, that is to say the neighborhood of B.


![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/local_com.png?raw=true)

On each iteration, the algorithm takes a point in U space and adds it to the community. Then it calculates the new modularity. If this is greater than the old one, then the node is added to the community.
There are two stopping conditions for this algorithm, either there is no new point allowing an improvement of the modularity at the end of a large number of iterations, or the whole of the graph has been traversed and there are no more points (vertex) to add to the community.

Once the community is found, we retrieve all the weights (ratings) of the links from this community and get an average rating which will be the predicted rating from this community.

# Results

For the recommandation part, we have 3 results : 3 ratings given, one by the community of the user described above, one by the community of the movie and the last one by the entire graph (that is to say all the user who have seen the movie selected and their ratings for that movie).

For the community of the movie, we keep the users that have seen more than 5 same movies in common with the user entered, including the movie intered. Then we calculate the mean of the ratings given by that community for that movie.

Here is the result :

<img src="https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/resultat.PNG?raw=true" width="100" height="100">

![alt text](https://github.com/Ainara2828/GraphTheory_MovieRecommandation/blob/main/images/resultat.PNG?raw=true)

