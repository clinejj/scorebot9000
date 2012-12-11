<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Player"%>
<%@ page import="com.csoft.clinelympics.Score"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!DOCTYPE html>
<html lang="en">
  <head>
  	<title>Clinelympics</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link type="text/css" rel="stylesheet" href="css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" href="css/bootstrap-responsive.min.css" />
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    <script type="application/javascript" src="js/bootstrap.min.js"></script>
  </head>

  <body>
  <h1>Clinelympics</h1>
  <div class="container">
  	<table class="table table-hover table-bordered">
    	<thead>
		<%
            DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
            Key gameKey = KeyFactory.createKey("Games", "gameList");
            Query gameQuery = new Query("game", gameKey).addSort("gameID", Query.SortDirection.ASCENDING);
            List<Entity> games = datastore.prepare(gameQuery).asList(FetchOptions.Builder.withLimit(100));
            if (games.isEmpty()) {
                %>
                <p>There was an error accessing the game list.</p>
                <%
            } else {
                %>
                <tr><th>Player</th>
                <%
                for (Entity game : games) {
                    %>
                    <th>
                    <%
                    pageContext.setAttribute("game_name", game.getProperty("gameName"));
                    %>
                    ${fn:escapeXml(game_name)}</th>
                    <%
                }
            }
        %>
        </tr>
        </thead>
        <tbody>
        <%
		    Key playerKey = KeyFactory.createKey("Players", "playerList");
			Query playerQuery = new Query("player", playerKey).addSort("playerID", Query.SortDirection.DESCENDING);
			List<Entity> players = datastore.prepare(playerQuery).asList(FetchOptions.Builder.withLimit(100));
			Key scoreKey = KeyFactory.createKey("Scores", "scoreList");
			Query scoreQuery = new Query("score", scoreKey).addSort("gameID", Query.SortDirection.ASCENDING);
			List<Entity> scores = datastore.prepare(scoreQuery).asList(FetchOptions.Builder.withLimit(players.size() * games.size()));
			if (players.isEmpty() || scores.isEmpty()) {
				%>
                <tr class="error">Error accessing players.</tr>
                <%
			} else if (!players.isEmpty() && !scores.isEmpty()) {
				HashMap displayPlayers = new HashMap();
				for (Entity ePlayer : players) {
					displayPlayers.put(ePlayer.getProperty("playerID"), new Player(ePlayer));	
				}
				for (Entity eScore : scores) {
					((Player) displayPlayers.get(eScore.getProperty("playerID"))).addScore(new Score(eScore));
				}
				for (Object dp : displayPlayers.values()) {
					pageContext.setAttribute("player_name", ((Player) dp).getPlayerName());
					%>
                    <tr><td>${fn:escapeXml(player_name)}</td>
                    <%
					for (Entity game : games) {
						Integer s = ((Player) dp).getScore(((Long) game.getProperty("gameID")).intValue());
						if (s == null) {
							pageContext.setAttribute("player_score", "");
						} else {
							pageContext.setAttribute("player_score", s);
						}
						%>
                        <td>${fn:escapeXml(player_score)}</td>
                        <%	
					}
					%>
                    </tr>
                    <%
				}
			}
		%>
        </tbody>
      </table>
    </div>
  </body>
</html>