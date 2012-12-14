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
<%@ page import="com.csoft.clinelympics.Medal"%>
<%@ page import="com.csoft.clinelympics.MedalScore"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="en">
  <head>
  	<title>Medals - Clinelympics</title>
    <c:import url="/components/head.html" />
  </head>

  <body>
    <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <a class="brand" href="/">Clinelympics</a>
      <ul class="nav">
        <li><a href="/">Home</a></li>
        <li><a href="/standings.jsp">Standings</a></li>
        <li class="active"><a href="/medals.jsp">Medals</a></li>
      </ul>
    </div>
  </div>
  <div class="container">
  	<div class="row">  <h1 style="text-align: center;">Medals</h1></div>
  	<div class="row"><h3>By Player:</h3></div>
    <div class = "row">
  	<table class="table table-hover table-bordered">
    	<thead>
		<%
            DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
						HashMap<String, HashMap> teams = new HashMap<String, HashMap>();
						HashMap<Object, Medal> playerMedals = new HashMap<Object, Medal>();
						HashMap<Object, Medal> teamMedals = new HashMap<Object, Medal>();
						
            Key gameKey = KeyFactory.createKey(Game.keyKind, Game.keyName);
            Query gameQuery = new Query(Game.entityKind, gameKey).addSort(Game.gameIDName, Query.SortDirection.ASCENDING);
            List<Entity> games = datastore.prepare(gameQuery).asList(FetchOptions.Builder.withDefaults());
            if (games.isEmpty()) {
                %>
                <tr class="error"><th>There was an error accessing the game list.</th></tr>
                <%
            } else {
                %>
                <tr><th></th>
                <%
                for (Entity game : games) {
										playerMedals.put(game.getProperty(Game.gameIDName), new Medal((Boolean) game.getProperty(Game.scoreTypeName)));
										teamMedals.put(game.getProperty(Game.gameIDName), new Medal((Boolean) game.getProperty(Game.scoreTypeName)));
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
				HashMap<Object, Player> displayPlayers = new HashMap<Object, Player>();
				for (Entity ePlayer : players) {
					displayPlayers.put(ePlayer.getProperty(Player.playerIDName), new Player(ePlayer));	
				}
				for (Entity eScore : scores) {
					((Player) displayPlayers.get(eScore.getProperty(Score.playerIDName))).addScore(new Score(eScore));
				}
				for (Player dp : displayPlayers.values()) {
					if (!teams.containsKey(dp.getTeamName())) {
						teams.put(dp.getTeamName(), new HashMap<Object, Integer>());
					}
					
					for (Entity game : games) {
						Integer s = (dp.getScore(((Long) game.getProperty(Game.gameIDName)).intValue()));
						if (s != null) {
							playerMedals.get(game.getProperty(Game.gameIDName)).addScore(dp.getPlayerName(), s);
							if (teams.get(dp.getTeamName()).containsKey(game.getProperty(Game.gameIDName))) {
								Integer ts = (Integer) teams.get(dp.getTeamName()).get(game.getProperty(Game.gameIDName));
								teams.get(dp.getTeamName()).put(game.getProperty(Game.gameIDName), s + ts);
							} else {
								teams.get(dp.getTeamName()).put(game.getProperty(Game.gameIDName), s);
							}
						}
					}
				}
			}
			
			for (int i=0;i<Medal.TOTAL_MEDALS;i++) {
				pageContext.setAttribute("medal_name", playerMedals.get(games.get(0).getProperty(Game.gameIDName)).getMedalNames().get(i));
				%> <tr><td>${fn:escapeXml(medal_name)}</td>
        <%
				for (Entity g : games) {
					Medal m = playerMedals.get(g.getProperty(Game.gameIDName));
					MedalScore s;
					if (i==0) {
						s = m.getScore(Medal.GOLD);
					} else if (i == 1) {
						s = m.getScore(Medal.SILVER);
					} else {
						s = m.getScore(Medal.BRONZE);	
					}
					if (s.displayName.equals("")) {
						pageContext.setAttribute("medal_score", "");
					} else {
						pageContext.setAttribute("medal_score", s.displayName + ": " + Integer.toString(s.score));
					}
					%><td>${fn:escapeXml(medal_score)}</td>
        	<%
				}
				%></tr><%
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
			for (String t : teams.keySet()) {
				for (Object g : teams.get(t).keySet()) {
					teamMedals.get(g).addScore(t, (Integer) teams.get(t).get(g));
				}
			}
			
			for (int i=0;i<Medal.TOTAL_MEDALS;i++) {
				pageContext.setAttribute("medal_name", teamMedals.get(games.get(0).getProperty(Game.gameIDName)).getMedalNames().get(i));
				%> <tr><td>${fn:escapeXml(medal_name)}</td>
        <%
				for (Entity g : games) {
					Medal m = teamMedals.get(g.getProperty(Game.gameIDName));
					MedalScore s;
					if (i==0) {
						s = m.getScore(Medal.GOLD);
					} else if (i == 1) {
						s = m.getScore(Medal.SILVER);
					} else {
						s = m.getScore(Medal.BRONZE);	
					}
					if (s.displayName.equals("")) {
						pageContext.setAttribute("medal_score", "");
					} else {
						pageContext.setAttribute("medal_score", s.displayName + ": " + Integer.toString(s.score));
					}
					%><td>${fn:escapeXml(medal_score)}</td>
        	<%
				}
				%></tr><%
			}
			%>
      </tbody>
      </table>
      </div>
    </div>
    <c:import url="/components/footer.html" />
  </body>
</html>