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
<%@ page import="com.csoft.clinelympics.Settings" %>
<%@ page import="com.csoft.clinelympics.Event" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

  <%
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Key settingsKey = KeyFactory.createKey(Settings.keyKind, Settings.keyName);
		Query query = new Query(Settings.entityKind, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		
		Key eventKey = KeyFactory.createKey(Event.keyKind, Event.keyName);
		query = new Query(Event.entityKind, eventKey).addSort(Event.eventIDName, Query.SortDirection.ASCENDING);
		Filter activeEvents = new FilterPredicate(Event.archivedName, FilterOperator.EQUAL, false);
		query.setFilter(activeEvents);
		List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		%>
<!DOCTYPE html>
<html lang="en">
  <head>
  <% if (settings.isEmpty()) { %>
    	<title>Scores</title>
  <% } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.siteNameName)); %>
      <title>Scores - ${fn:escapeXml(site_name)}</title>
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
          <% 
					if (!events.isEmpty()) { %>
            <ul class="nav">
              <li class="divider-vertical"></li>
              <%
							if (events.size() == 1) {
								%>
              	<li><a href="/summary.jsp">Summary</a></li>
                <%
							} else {
								%>
                <li class="dropdown">
                  <a href="/summary.jsp" class="dropdown-toggle" data-toggle="dropdown">
                    Summary
                    <b class="caret"></b>
                  </a>
                  <ul class="dropdown-menu">
                  <%
									for (Entity ce : events) {
										pageContext.setAttribute("event_id", ce.getProperty(Event.eventIDName));
										pageContext.setAttribute("event_name", ce.getProperty(Event.eventNameName));
										%>
                    <li><a href="/summary.jsp?e=${fn:escapeXml(event_id)}">${fn:escapeXml(event_name)}</a></li>
                    <%
									}
									%>
                  </ul>
                </li>
                <%
							}
							%>
              <li class="active"><a href="/scores.jsp">Scores</a></li>
              <li><a href="/medals.jsp">Medals</a></li>
              <li class="divider-vertical"></li>
            </ul>
      			<% 
					} 
				}
			%>
      <div class="pull-right">
      	<ul class="nav">
         <li class="dropdown pull-right">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown">
              <b class="caret"></b>
            </a>
            <ul class="dropdown-menu pull-right">
              <li><a href="/admin.jsp">Admin</a></li>
            </ul>
         </li>
        </ul>
      </div>
    </div>
  </div>
  <div class="container">
  <% if (settings.isEmpty()) {   %>
    <div class="row"><p class="text-error">This site has not been configured.</p></div>
    <% } else { %>
  	<div class="row"><h1 style="text-align: center;">Scores</h1></div>
  	<div class="row"><h3>By Player:</h3></div>
    <div class = "row">
  	<table class="table table-hover table-bordered">
    	<thead>
		<%
						HashMap<String, HashMap> teams = new HashMap<String, HashMap>();
            Key gameKey = KeyFactory.createKey(Game.keyKind, Game.keyName);
            Query gameQuery = new Query(Game.entityKind, gameKey).addSort(Game.gameIDName, Query.SortDirection.ASCENDING);
						Filter feID = new FilterPredicate(Game.eventIDName, FilterOperator.EQUAL, ((Long) settings.get(0).getProperty(Settings.curEventName)).intValue());
						gameQuery.setFilter(feID);
            List<Entity> games = datastore.prepare(gameQuery).asList(FetchOptions.Builder.withDefaults());
            if (games.isEmpty()) {
                %>
                <tr class="error"><th>There was an error accessing the game list.</th></tr>
                <%
            } else {
                %>
                <tr><th>Player</th><th>Team</th>
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
				playerQuery.setFilter(feID);
				List<Entity> players = datastore.prepare(playerQuery).asList(FetchOptions.Builder.withDefaults());
				
				Key scoreKey = KeyFactory.createKey(Score.keyKind, Score.keyName);
				Query scoreQuery = new Query(Score.entityKind, scoreKey).addSort(Score.gameIDName, Query.SortDirection.ASCENDING);
				scoreQuery.setFilter(feID);
				List<Entity> scores = datastore.prepare(scoreQuery).asList(FetchOptions.Builder.withDefaults());
				
				if (players.isEmpty() || scores.isEmpty()) {    System.out.println(scores.isEmpty());%>
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
						pageContext.setAttribute("team_name", ((Player) dp).getTeamName());
						if (!teams.containsKey(((Player) dp).getTeamName())) {
							teams.put(((Player) dp).getTeamName(), new HashMap<Object, Integer>());
						}
						%>
                    <tr><td>${fn:escapeXml(player_name)}</td><td>${fn:escapeXml(team_name)}</td>
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
    <% } %>
    <c:import url="/components/footer.html" />
  </body>
</html>