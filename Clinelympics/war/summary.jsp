<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Collections" %>
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
		
		Key eventKey = KeyFactory.createKey(Event.keyKind, Event.keyName);
		query = new Query(Event.entityKind, eventKey).addSort(Event.eventIDName, Query.SortDirection.ASCENDING);
		Filter activeEvents = new FilterPredicate(Event.archivedName, FilterOperator.EQUAL, false);
		query.setFilter(activeEvents);
		List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		%>
<!DOCTYPE html>
<html lang="en">
  <head>
  	<% 
		if (settings.isEmpty()) { 
			%>
    	<title>Summary</title>
		<% 
    } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.siteNameName)); %>
      <title>Summary - ${fn:escapeXml(site_name)}</title>
  		<% 
		} 
		%>
    <c:import url="/components/head.html" />
  </head>

  <body>
  <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <% if (settings.isEmpty()) { %>
          <a class="brand" href="/">Scorebot 9000</a>
      <% } else { %>
          <a class="brand" href="/">${fn:escapeXml(site_name)}</a>
          <% 
					if (!events.isEmpty()) { %>
            <ul class="nav">
              <li class="divider-vertical"></li>
              <%
							if (events.size() == 1) {
								%>
              	<li class="active"><a href="/summary.jsp">Summary</a></li>
                <%
							} else {
								%>
                <li class="dropdown active">
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
              <li><a href="/scores.jsp">Scores</a></li>
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
    <%	
		if (settings.isEmpty()) {  
			%>
    	<div class="row"><div class="alert alert-error">This site has not been configured.</div></div>
    	<% 
		} else { 
			Settings s = new Settings(settings.get(0));
			int eventID = s.getCurEventID();
			if (request.getParameter("e") != null) {
				eventID = Integer.parseInt(request.getParameter("e"));
			}
			Filter feID = new FilterPredicate(Event.eventIDName, FilterOperator.EQUAL, eventID);
			query.setFilter(feID);
			events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
			if (events.isEmpty()) {
				%>
				<div class="row"><div class="alert alert-error">The event you wanted doesn't exist. Sorry!.</div></div>
				<%		
			} else { 		
				Event e = new Event(events.get(0));
				pageContext.setAttribute("event_name", e.getEventName());
				%>
				<div class="row"><h2 style="text-align: center;">Summary of ${fn:escapeXml(event_name)}</h2></div>
				<%
				Key gameKey = KeyFactory.createKey(Game.keyKind, Game.keyName);
				Query gameQuery = new Query(Game.entityKind, gameKey).addSort(Game.gameIDName, Query.SortDirection.ASCENDING);
				gameQuery.setFilter(feID);
				List<Entity> games = datastore.prepare(gameQuery).asList(FetchOptions.Builder.withDefaults());
				if (games.isEmpty()) {						
					%>
					<div class="alert alert-error">There was an error accessing the game list.</div>
					<%
				} else {
					Key playerKey = KeyFactory.createKey(Player.keyKind, Player.keyName);
					Query playerQuery = new Query(Player.entityKind, playerKey).addSort(Player.playerIDName, Query.SortDirection.DESCENDING);
					playerQuery.setFilter(feID);
					List<Entity> players = datastore.prepare(playerQuery).asList(FetchOptions.Builder.withDefaults());
					
					Key scoreKey = KeyFactory.createKey(Score.keyKind, Score.keyName);
					Query scoreQuery = new Query(Score.entityKind, scoreKey).addSort(Score.gameIDName, Query.SortDirection.ASCENDING);
					scoreQuery.setFilter(feID);
					List<Entity> scores = datastore.prepare(scoreQuery).asList(FetchOptions.Builder.withDefaults());	
					
					if (players.isEmpty() || scores.isEmpty()) {    
						System.out.println(scores.isEmpty());
						%>
						<div class="alert alert-error">Error accessing player scores.</div>
						<%
					} else if (!players.isEmpty() && !scores.isEmpty()) {		
						// Setup variables
						String[] medalNames = e.getEventMedals().split(",");
						HashMap<String, HashMap> teams = new HashMap<String, HashMap>();
						HashMap<Object, Medal> playerMedals = new HashMap<Object, Medal>();
						HashMap<Object, Medal> teamMedals = new HashMap<Object, Medal>();
						HashMap<Object, HashMap> teamCount = new HashMap<Object, HashMap>();
						HashMap<Object, HashMap> playerCount = new HashMap<Object, HashMap>();
						ArrayList<Medal> teamDisplay = new ArrayList<Medal>();
				
						HashMap displayPlayers = new HashMap();
						
						// Setup medal storage
						for (Entity game : games) {
							playerMedals.put(game.getProperty(Game.gameIDName), new Medal(e.getEventMedals(),(Boolean) game.getProperty(Game.scoreTypeName)));
							teamMedals.put(game.getProperty(Game.gameIDName), new Medal(e.getEventMedals(), (Boolean) game.getProperty(Game.scoreTypeName)));
						}
						
						// Get list of players for display
						for (Entity ePlayer : players) {
							displayPlayers.put(ePlayer.getProperty(Player.playerIDName), new Player(ePlayer));
							playerCount.put((String) ePlayer.getProperty(Player.playerNameName), new HashMap<String, Integer>());
							for (String m : medalNames) {
								playerCount.get((String) ePlayer.getProperty(Player.playerNameName)).put(m, 0);
							}
							playerCount.get((String) ePlayer.getProperty(Player.playerNameName)).put("total", 0);
						}
						
						// Add scores to player display
						for (Entity eScore : scores) {
							((Player) displayPlayers.get(eScore.getProperty(Score.playerIDName))).addScore(new Score(eScore));
						}
						
						// Display players
						for (Object dp : displayPlayers.values()) {
							// Setup teams
							if (!teams.containsKey(((Player) dp).getTeamName())) {
								teams.put(((Player) dp).getTeamName(), new HashMap<Object, Integer>());
								teamCount.put(((Player) dp).getTeamName(), new HashMap<String, Integer>());
								for (String m : medalNames) {
									teamCount.get(((Player) dp).getTeamName()).put(m, 0);
								}
								teamCount.get(((Player) dp).getTeamName()).put("total", 0);
							}
							
							// Display player scores
							for (Entity game : games) {
								Integer sc = ((Player) dp).getScore(((Long) game.getProperty(Game.gameIDName)).intValue());
								// Add to medals
								if (sc != null) {
									playerMedals.get(game.getProperty(Game.gameIDName)).addScore(((Player) dp).getPlayerName(), sc);
									if (teams.get(((Player) dp).getTeamName()).containsKey(game.getProperty(Game.gameIDName))) {
										Integer ts = (Integer) teams.get(((Player) dp).getTeamName()).get(game.getProperty(Game.gameIDName));
										teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.gameIDName), sc + ts);
									} else {
										teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.gameIDName), sc);
									}
								}	
							}
						}
		
						// Create team medals
						for (String t : teams.keySet()) {
							for (Object g : teams.get(t).keySet()) {
								teamMedals.get(g).addScore(t, (Integer) teams.get(t).get(g));
							}
						}
						
						// Count team medals
						for (Medal tm : teamMedals.values()) {
							for (String n : medalNames) {
								MedalScore ms = tm.getScore(n);
								if (!ms.displayName.equals("")) {
									if (ms.displayName.contains(",")) {
										String[] names = ms.displayName.split(", ");
										for (String ns : names) {
											teamCount.get(ns).put(n, ((Integer) teamCount.get(ns).get(n)) + 1);
											teamCount.get(ns).put("total", ((Integer) teamCount.get(ns).get("total")) + 1);
										}
										
									} else {
										teamCount.get(ms.displayName).put(n, ((Integer) teamCount.get(ms.displayName).get(n)) + 1);
										teamCount.get(ms.displayName).put("total", ((Integer) teamCount.get(ms.displayName).get("total")) + 1);
									}
								}
							}
						}
						
						for (Object t : teamCount.keySet()) {
							// sort medals
							teamDisplay.add(0, new Medal("total," + e.getEventMedals(), true, (String) t));
							teamDisplay.get(0).addScore("total", new MedalScore("", ((Integer) teamCount.get((String) t).get("total"))));
							for (String m : medalNames) {
								teamDisplay.get(0).addScore(m, new MedalScore("", ((Integer) teamCount.get((String) t).get(m))));
							}
						}
						
						Collections.sort(teamDisplay);
						
						%>
            <div class="row"><h3>Team Medal Count:</h3></div>
            <div class = "row">
            <table class="table table-hover table-bordered">
            <thead>
            <tr><th></th>
            <%
						for (String n : medalNames) {
							pageContext.setAttribute("medal_name", n);
							%>
              <th>${fn:escapeXml(medal_name)}</th>
              <%
						}
						%>
            <th>Total</th></tr></thead>
            <tbody>
            <%
						for (Medal m : teamDisplay) {
						//for (Object tn : teamCount.keySet()) {
							//System.out.println(tn);
							pageContext.setAttribute("team_name", m.getDisplayName());
							//pageContext.setAttribute("team_name", tn);
							%>
              <tr><td>${fn:escapeXml(team_name)}</td>
              <%
							for (String n : medalNames) {
								pageContext.setAttribute("medal_count", m.getScore(n).score);
								//pageContext.setAttribute("medal_count", teamCount.get(tn).get(n));
								%>
                <td>${fn:escapeXml(medal_count)}</td>
                <%
							}
							pageContext.setAttribute("total_count", m.getScore("total").score);
							//pageContext.setAttribute("total_count", teamCount.get(tn).get("total"));
							%>
              <td>${fn:escapeXml(total_count)}</td></tr>
              <%
						}
						%>
            </tbody>
            </table>
            </div>
            <%
						
						// Count player medals
						for (Medal pm : playerMedals.values()) {
							for (String n : medalNames) {
								MedalScore ms = pm.getScore(n);
								if (!ms.displayName.equals("")) {
									if (ms.displayName.contains(",")) {
										String[] names = ms.displayName.split(", ");
										for (String ns : names) {
											playerCount.get(ns).put(n, ((Integer) playerCount.get(ns).get(n)) + 1);
										}
									} else {
										playerCount.get(ms.displayName).put(n, ((Integer) playerCount.get(ms.displayName).get(n)) + 1);
									}
								}
							}
						}
						
					
						%>
						<div class="row"><h3>Medals By Team:</h3></div>
						<div class = "row">
						<table class="table table-hover table-bordered">
    				<thead>
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
        		%>
            </tr>
            </thead>
            <tbody>
						<%	
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
            <%
					}		
				}
			} 
		} 
		%>
    </div>
    <c:import url="/components/footer.html" />
  </body>
</html>