<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Query.Filter" %>
<%@ page import="com.google.appengine.api.datastore.Query.FilterPredicate" %>
<%@ page import="com.google.appengine.api.datastore.Query.FilterOperator" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Player"%>
<%@ page import="com.csoft.clinelympics.Score"%>
<%@ page import="com.csoft.clinelympics.Game"%>
<%@ page import="com.csoft.clinelympics.Medal"%>
<%@ page import="com.csoft.clinelympics.MedalScore"%>
<%@ page import="com.csoft.clinelympics.Settings" %>
<%@ page import="com.csoft.clinelympics.Event" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

  <%
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Key settingsKey = KeyFactory.createKey(Settings.keyKind, Settings.keyName);
		Query query = new Query(Settings.entityKind, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		%>
<!DOCTYPE html>
<html lang="en">
  <head>
  <% if (settings.isEmpty()) { %>
    	<title>Medals</title>
  <% } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.siteNameName)); %>
      <title>Medals - ${fn:escapeXml(site_name)}</title>
  <% } %>
    <c:import url="/components/head.html" />
  </head>

  <body>
  <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <% if (settings.isEmpty()) { %>
          <a class="brand" href="/">Clinelympics</a>
      <% } else { %>
          <a class="brand" href="/">${fn:escapeXml(site_name)}</a>
      <% } %>
      <ul class="nav">
        <li><a href="/">Home</a></li>
        <li><a href="/standings.jsp">Standings</a></li>
        <li class="active"><a href="/medals.jsp">Medals</a></li>
      </ul>
    </div>
  </div>
  <div class="container">
    <%	if (settings.isEmpty()) {  %>
    <div class="row"><p class="text-error">This site has not been configured.</p></div>
    <% } else { 
					Settings s = new Settings(settings.get(0));
					Key eventKey = KeyFactory.createKey(Event.keyKind, Event.keyName);
					query = new Query(Event.entityKind, eventKey).addSort(Event.eventIDName, Query.SortDirection.ASCENDING);
					Filter feID = new FilterPredicate(Event.eventIDName, FilterOperator.EQUAL, s.getCurEventID());
					query.setFilter(feID);
					List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					if (events.isEmpty()) {
		%>
    <div class="row"><p class="text-error">There is no current event.</p></div>
    <%		} else { 		%>
            <div class="row">  <h1 style="text-align: center;">Medals</h1></div>
            <div class="row"><h3>By Player:</h3></div>
            <div class = "row">
            <table class="table table-hover table-bordered">
              <thead>
						<%
						Event e = new Event(events.get(0));
						String[] medalNames = e.getEventMedals().split(",");
						HashMap<String, HashMap> teams = new HashMap<String, HashMap>();
						HashMap<Object, Medal> playerMedals = new HashMap<Object, Medal>();
						HashMap<Object, Medal> teamMedals = new HashMap<Object, Medal>();
						
            Key gameKey = KeyFactory.createKey(Game.keyKind, Game.keyName);
            Query gameQuery = new Query(Game.entityKind, gameKey).addSort(Game.gameIDName, Query.SortDirection.ASCENDING);
						gameQuery.setFilter(feID);
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
										playerMedals.put(game.getProperty(Game.gameIDName), new Medal(e.getEventMedals(),(Boolean) game.getProperty(Game.scoreTypeName)));
										teamMedals.put(game.getProperty(Game.gameIDName), new Medal(e.getEventMedals(), (Boolean) game.getProperty(Game.scoreTypeName)));
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
          playerQuery.setFilter(feID);
          List<Entity> players = datastore.prepare(playerQuery).asList(FetchOptions.Builder.withDefaults());
          
          Key scoreKey = KeyFactory.createKey(Score.keyKind, Score.keyName);
          Query scoreQuery = new Query(Score.entityKind, scoreKey).addSort(Score.gameIDName, Query.SortDirection.ASCENDING);
          scoreQuery.setFilter(feID);
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
								Integer sc = (dp.getScore(((Long) game.getProperty(Game.gameIDName)).intValue()));
								if (sc != null) {
									playerMedals.get(game.getProperty(Game.gameIDName)).addScore(dp.getPlayerName(), sc);
									if (teams.get(dp.getTeamName()).containsKey(game.getProperty(Game.gameIDName))) {
										Integer ts = (Integer) teams.get(dp.getTeamName()).get(game.getProperty(Game.gameIDName));
										teams.get(dp.getTeamName()).put(game.getProperty(Game.gameIDName), sc + ts);
									} else {
										teams.get(dp.getTeamName()).put(game.getProperty(Game.gameIDName), sc);
									}
								}
							}
						}
					}

			for (int i=0;i<medalNames.length;i++) {
				pageContext.setAttribute("medal_name", medalNames[i]);
				%> <tr><td>${fn:escapeXml(medal_name)}</td>
        <%
				for (Entity g : games) {
					Medal m = playerMedals.get(g.getProperty(Game.gameIDName));
					MedalScore ms = m.getScore(medalNames[i]);
					if (ms.displayName.equals("") || (ms.score == Integer.MAX_VALUE) || (ms.score == Integer.MIN_VALUE)) {
						pageContext.setAttribute("medal_score", "");
					} else {
						pageContext.setAttribute("medal_score", ms.displayName + ": " + Integer.toString(ms.score));
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
			
			for (int i=0;i<medalNames.length;i++) {
				pageContext.setAttribute("medal_name", medalNames[i]);
				%> <tr><td>${fn:escapeXml(medal_name)}</td>
        <%
				for (Entity g : games) {
					Medal m = teamMedals.get(g.getProperty(Game.gameIDName));
					MedalScore ms = m.getScore(medalNames[i]);
					if (ms.displayName.equals("") || (ms.score == Integer.MAX_VALUE) || (ms.score == Integer.MIN_VALUE)) {
						pageContext.setAttribute("medal_score", "");
					} else {
						pageContext.setAttribute("medal_score", ms.displayName + ": " + Integer.toString(ms.score));
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
        <% } } %>
    <c:import url="/components/footer.html" />
  </body>
</html>