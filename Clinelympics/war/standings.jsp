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
<%@ page import="com.csoft.clinelympics.Game"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="en">
  <head>
  	<title>Standings - Clinelympics</title>
    <c:import url="/components/head.html" />
  </head>

  <body>
    <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <a class="brand" href="/">Clinelympics</a>
      <ul class="nav">
        <li><a href="/">Home</a></li>
        <li class="active"><a href="/standings.jsp">Standings</a></li>
        <li><a href="/medals.jsp">Medals</a></li>
      </ul>
    </div>
  </div>
  <div class="container">
  	<div class="row"><h1 style="text-align: center;">Standings</h1></div>
  	<div class="row"><h3>By Player:</h3></div>
    <div class = "row">
  	<table class="table table-hover table-bordered">
    	<thead>
		<%
            DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
						HashMap<String, HashMap> teams = new HashMap<String, HashMap>();
            Key gameKey = KeyFactory.createKey(Game.keyKind, Game.keyName);
            Query gameQuery = new Query(Game.entityKind, gameKey).addSort(Game.gameIDName, Query.SortDirection.ASCENDING);
            List<Entity> games = datastore.prepare(gameQuery).asList(FetchOptions.Builder.withDefaults());
            if (games.isEmpty()) {
                %>
                <tr class="error"><th>There was an error accessing the game list.</th></tr>
                <%
            } else {
                %>
                <tr><th>Player</th>
                <%
                for (Entity game : games) {
                    %>
                    <th>
                    <%
                    pageContext.setAttribute("game_name", game.getProperty(Game.gameNameName));
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
		    Key playerKey = KeyFactory.createKey(Player.keyKind, Player.keyName);
			Query playerQuery = new Query(Player.entityKind, playerKey).addSort(Player.playerIDName, Query.SortDirection.DESCENDING);
			List<Entity> players = datastore.prepare(playerQuery).asList(FetchOptions.Builder.withDefaults());
			Key scoreKey = KeyFactory.createKey(Score.keyKind, Score.keyName);
			Query scoreQuery = new Query(Score.entityKind, scoreKey).addSort(Score.gameIDName, Query.SortDirection.ASCENDING);
			List<Entity> scores = datastore.prepare(scoreQuery).asList(FetchOptions.Builder.withDefaults());
			if (players.isEmpty() || scores.isEmpty()) {
				%>
                <tr class="error">Error accessing players.</tr>
                <%
			} else if (!players.isEmpty() && !scores.isEmpty()) {
				HashMap displayPlayers = new HashMap();
				for (Entity ePlayer : players) {
					displayPlayers.put(ePlayer.getProperty(Player.playerIDName), new Player(ePlayer));	
				}
				for (Entity eScore : scores) {
					((Player) displayPlayers.get(eScore.getProperty(Score.playerIDName))).addScore(new Score(eScore));
				}
				for (Object dp : displayPlayers.values()) {
					pageContext.setAttribute("player_name", ((Player) dp).getPlayerName());
					if (!teams.containsKey(((Player) dp).getTeamName())) {
						teams.put(((Player) dp).getTeamName(), new HashMap<Object, Integer>());
					}
					%>
                    <tr><td>${fn:escapeXml(player_name)}</td>
                    <%
					for (Entity game : games) {
						Integer s = ((Player) dp).getScore(((Long) game.getProperty(Game.gameIDName)).intValue());
						if (s == null) {
							pageContext.setAttribute("player_score", "");
						} else {
							pageContext.setAttribute("player_score", s);
							if (teams.get(((Player) dp).getTeamName()).containsKey(game.getProperty(Game.gameIDName))) {
								Integer ts = (Integer) teams.get(((Player) dp).getTeamName()).get(game.getProperty(Game.gameIDName));
								teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.gameIDName), s + ts);
							} else {
								teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.gameIDName), s);
							}
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
        	<div class="row"><h3>By Team:</h3></div>
    <div class = "row">
  	<table class="table table-hover table-bordered">
    	<thead>
      <%
			if (games.isEmpty()) {
                %>
                <tr class="error"><th>There was an error accessing the game list.</th></tr>
                <%
            } else {
                %>
                <tr><th>Team</th>
                <%
                for (Entity game : games) {
                    %>
                    <th>
                    <%
                    pageContext.setAttribute("game_name", game.getProperty(Game.gameNameName));
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
			for (String tname : teams.keySet()) {
				pageContext.setAttribute("team_name", tname);
				%>
        <tr><td>${fn:escapeXml(team_name)}</td>
        <%
				//loop through scores
					for (Entity game : games) {
						if (teams.get(tname).containsKey(game.getProperty(Game.gameIDName))) {
							pageContext.setAttribute("team_score", teams.get(tname).get(game.getProperty(Game.gameIDName)));
						} else {
							pageContext.setAttribute("team_score", "");
						}
						%>
            <td>${fn:escapeXml(team_score)}</td>
            <%
					}
				%>
        </tr>
        <%
			}
			%>
      </tbody>
      </table>
      </div>
    </div>
    <c:import url="/components/footer.html" />
  </body>
</html>