<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.TreeMap" %>
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
<%@ page import="com.csoft.scorebot.Player"%>
<%@ page import="com.csoft.scorebot.Score"%>
<%@ page import="com.csoft.scorebot.Game"%>
<%@ page import="com.csoft.scorebot.Medal"%>
<%@ page import="com.csoft.scorebot.MedalScore"%>
<%@ page import="com.csoft.scorebot.Settings" %>
<%@ page import="com.csoft.scorebot.Event" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

  <%
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Key settingsKey = KeyFactory.createKey(Settings.KEY_KIND, Settings.KEY_NAME);
		Query query = new Query(Settings.ENTITY_KIND, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		
		Key eventKey = KeyFactory.createKey(Event.KEY_KIND, Event.KEY_NAME);
		query = new Query(Event.ENTITY_KIND, eventKey).addSort(Event.EVENT_ID, Query.SortDirection.ASCENDING);
		Filter unArchivedEvents = new FilterPredicate(Event.ARCHIVED_NAME, FilterOperator.EQUAL, false);
		query.setFilter(unArchivedEvents);
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
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.SITE_NAME)); %>
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
              	<li ><a href="/summary.jsp">Summary</a></li>
                <%
							} else {
								%>
                <li class="dropdown">
                	<%
                  if (((Long) settings.get(0).getProperty(Settings.CUR_EVENT)).intValue() != -1) {
										%>
                    <a href="/summary.jsp" class="dropdown-toggle" data-toggle="dropdown">
                      Summary
                      <b class="caret"></b>
                    </a>
                    <%
									} else {
										pageContext.setAttribute("event_id", events.get(0).getProperty(Event.EVENT_ID));
										%>
                    <a href="/summary.jsp?e=${fn:escapeXml(event_id)}" class="dropdown-toggle" data-toggle="dropdown">
                      Summary
                      <b class="caret"></b>
                    </a>
                    <%
									}
									%>
                  <ul class="dropdown-menu">
                  <%
									for (Entity ce : events) {
										pageContext.setAttribute("event_id", ce.getProperty(Event.EVENT_ID));
										pageContext.setAttribute("event_name", ce.getProperty(Event.EVENT_NAME));
										%>
                    <li><a href="/summary.jsp?e=${fn:escapeXml(event_id)}">${fn:escapeXml(event_name)}</a></li>
                    <%
									}
									%>
                  </ul>
                </li>
                <%
							}
							if (((Long) settings.get(0).getProperty(Settings.CUR_EVENT)).intValue() != -1) {
								%>
								<li><a href="/medals.jsp">Medals</a></li>
								<li><a href="/scores.jsp">Scores</a></li>				
                <%
							}
							%>
              <li class="divider-vertical"></li>
            </ul>
      			<% 
					} 
				}
			%>
      <div class="pull-right">
      	<ul class="nav">
         <li class="dropdown pull-right">
            <a href="#" class="dropdown-toggle active" data-toggle="dropdown">
              <b class="caret"></b>
            </a>
            <ul class="dropdown-menu pull-right">
              <li class="active"><a href="/admin.jsp">Admin</a></li>
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
      <div class="row"><p></p></div>
    	<div class="row"><div class="alert alert-error">This site has not been configured.</div></div>
    	<% 
		} else { 
			Settings s = new Settings(settings.get(0));
			int eventID = s.getCurEventID();
			if (request.getParameter("e") != null) {
				eventID = Integer.parseInt(request.getParameter("e"));
			}
			Filter feID = new FilterPredicate(Event.EVENT_ID, FilterOperator.EQUAL, eventID);
			query.setFilter(feID);
			events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
			if (events.isEmpty()) {
				%>
        <div class="row"><p></p></div>
				<div class="row"><div class="alert alert-error">The event you wanted doesn't exist. Sorry!.</div></div>
				<%		
			} else { 		
				Event e = new Event(events.get(0));
				pageContext.setAttribute("event_name", e.getEventName());
				%>
				<div class="row"><h2 style="text-align: center;">Summary of ${fn:escapeXml(event_name)}</h2></div>
				<%
				Key gameKey = KeyFactory.createKey(Game.KEY_KIND, Game.KEY_NAME);
				Query gameQuery = new Query(Game.ENTITY_KIND, gameKey).addSort(Game.GAME_ID, Query.SortDirection.ASCENDING);
				gameQuery.setFilter(feID);
				List<Entity> games = datastore.prepare(gameQuery).asList(FetchOptions.Builder.withDefaults());
				if (games.isEmpty()) {						
					%>
					<div class="alert alert-error">There was an error accessing the game list.</div>
					<%
				} else {
					Key playerKey = KeyFactory.createKey(Player.KEY_KIND, Player.KEY_NAME);
					Query playerQuery = new Query(Player.ENTITY_KIND, playerKey).addSort(Player.TEAM_NAME, Query.SortDirection.ASCENDING);
					playerQuery.addSort(Player.PLAYER_NAME, Query.SortDirection.ASCENDING);
					playerQuery.setFilter(feID);
					List<Entity> players = datastore.prepare(playerQuery).asList(FetchOptions.Builder.withDefaults());
					
					Key scoreKey = KeyFactory.createKey(Score.KEY_KIND, Score.KEY_NAME);
					Query scoreQuery = new Query(Score.ENTITY_KIND, scoreKey).addSort(Score.GAME_ID, Query.SortDirection.ASCENDING);
					scoreQuery.setFilter(feID);
					List<Entity> scores = datastore.prepare(scoreQuery).asList(FetchOptions.Builder.withDefaults());	
					
					if (players.isEmpty() || scores.isEmpty()) {    
						%>
						<div class="alert alert-info">There are no scores for this game yet.</div>
						<%
					} else if (!players.isEmpty() && !scores.isEmpty()) {		
						// Setup variables
						String[] medalNames = e.getEventMedals().split(",");
						TreeMap<String, HashMap> teams = new TreeMap<String, HashMap>();
						HashMap<Object, Medal> playerMedals = new HashMap<Object, Medal>();
						HashMap<Object, Medal> teamMedals = new HashMap<Object, Medal>();
						HashMap<Object, HashMap> teamCount = new HashMap<Object, HashMap>();
						HashMap<Object, HashMap> playerCount = new HashMap<Object, HashMap>();
						HashMap<String, String> playerTeams = new HashMap<String, String>();
						ArrayList<Medal> teamDisplay = new ArrayList<Medal>();
						ArrayList<Medal> playerDisplay = new ArrayList<Medal>();
				
						HashMap displayPlayers = new HashMap();
						
						// Setup medal storage
						for (Entity game : games) {
							playerMedals.put(game.getProperty(Game.GAME_ID), new Medal(e.getEventMedals(),(Boolean) game.getProperty(Game.SCORE_TYPE)));
							teamMedals.put(game.getProperty(Game.GAME_ID), new Medal(e.getEventMedals(), (Boolean) game.getProperty(Game.SCORE_TYPE)));
						}
						
						// Get list of players for display
						for (Entity ePlayer : players) {
							displayPlayers.put(ePlayer.getProperty(Player.PLAYER_ID), new Player(ePlayer));
							playerCount.put((String) ePlayer.getProperty(Player.PLAYER_NAME), new HashMap<String, Integer>());
							for (String m : medalNames) {
								playerCount.get((String) ePlayer.getProperty(Player.PLAYER_NAME)).put(m, 0);
							}
							playerCount.get((String) ePlayer.getProperty(Player.PLAYER_NAME)).put("total", 0);
						}
						
						// Add scores to player display
						for (Entity eScore : scores) {
							((Player) displayPlayers.get(eScore.getProperty(Score.PLAYER_ID))).addScore(new Score(eScore));
						}
						
						// Generate teams
						for (Object dp : displayPlayers.values()) {
							// Setup teams
							playerTeams.put((String) ((Player) dp).getPlayerName(), (String) ((Player) dp).getTeamName());
							if (!teams.containsKey(((Player) dp).getTeamName())) {
								teams.put(((Player) dp).getTeamName(), new HashMap<Object, Integer>());
								teamCount.put(((Player) dp).getTeamName(), new HashMap<String, Integer>());
								for (String m : medalNames) {
									teamCount.get(((Player) dp).getTeamName()).put(m, 0);
								}
								teamCount.get(((Player) dp).getTeamName()).put("total", 0);
							}
							
							// Store player scores
							for (Entity game : games) {
								Integer sc = ((Player) dp).getScore(((Long) game.getProperty(Game.GAME_ID)).intValue());
								// Add to medals
								if (sc != null) {
									playerMedals.get(game.getProperty(Game.GAME_ID)).addScore(((Player) dp).getPlayerName(), sc);
									if (teams.get(((Player) dp).getTeamName()).containsKey(game.getProperty(Game.GAME_ID))) {
										Integer ts = (Integer) teams.get(((Player) dp).getTeamName()).get(game.getProperty(Game.GAME_ID));
										teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.GAME_ID), sc + ts);
									} else {
										teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.GAME_ID), sc);
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
						
						if (e.isTeamScore()) {
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
						} else {
							// Count player medals
							for (Medal pm : playerMedals.values()) {
								for (String n : medalNames) {
									MedalScore ms = pm.getScore(n);
									if (!ms.displayName.equals("")) {
										if (ms.displayName.contains(",")) {
											String[] names = ms.displayName.split(", ");
											for (String ns : names) {
												playerCount.get(ns).put(n, ((Integer) playerCount.get(ns).get(n)) + 1);
												playerCount.get(ns).put("total", ((Integer) playerCount.get(ns).get("total")) + 1);
												teamCount.get(playerTeams.get(ns)).put(n, ((Integer) teamCount.get(playerTeams.get(ns)).get(n)) + 1);
												teamCount.get(playerTeams.get(ns)).put("total", ((Integer) teamCount.get(playerTeams.get(ns)).get("total")) + 1);
											}
										} else {
											playerCount.get(ms.displayName).put(n, ((Integer) playerCount.get(ms.displayName).get(n)) + 1);
											playerCount.get(ms.displayName).put("total", ((Integer) playerCount.get(ms.displayName).get("total")) + 1);
											teamCount.get(playerTeams.get(ms.displayName)).put(n, ((Integer) teamCount.get(playerTeams.get(ms.displayName)).get(n)) + 1);
											teamCount.get(playerTeams.get(ms.displayName)).put("total", ((Integer) teamCount.get(playerTeams.get(ms.displayName)).get("total")) + 1);
										}
									}
								}
							}
							
							for (Object t : playerCount.keySet()) {
								// sort medals
								playerDisplay.add(0, new Medal("total," + e.getEventMedals(), true, (String) t));
								playerDisplay.get(0).addScore("total", new MedalScore("", ((Integer) playerCount.get((String) t).get("total"))));
								for (String m : medalNames) {
									playerDisplay.get(0).addScore(m, new MedalScore("", ((Integer) playerCount.get((String) t).get(m))));
								}
							}
							
							Collections.sort(playerDisplay);
						}
						
						if (e.usesTeams()) {
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
							<tr><th>Team</th>
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
								pageContext.setAttribute("team_name", m.getDisplayName());
								%>
								<tr><td>${fn:escapeXml(team_name)}</td>
								<%
								for (String n : medalNames) {
									pageContext.setAttribute("medal_count", m.getScore(n).score);
									%>
									<td>${fn:escapeXml(medal_count)}</td>
									<%
								}
								pageContext.setAttribute("total_count", m.getScore("total").score);
								%>
								<td>${fn:escapeXml(total_count)}</td></tr>
								<%
							}
							%>
							</tbody>
							</table>
							</div>
							<%
						}
						if (!e.isTeamScore()) {
							%>
							<div class="row"><h3>Player Medal Count:</h3></div>
							<div class = "row">
							<table class="table table-hover table-bordered">
							<thead>
							<tr><th>Player</th>
              <% if (e.usesTeams()) {
								%>
                <th>Team</th>
                <%
							}
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
							for (Medal m : playerDisplay) {
								pageContext.setAttribute("player_name", m.getDisplayName());
									pageContext.setAttribute("team_name", playerTeams.get(m.getDisplayName()));
								%>
								<tr><td>${fn:escapeXml(player_name)}</td>
                <%
								if (e.usesTeams()) {
									%>
									<td>${fn:escapeXml(team_name)}</td>
									<%
								}
								for (String n : medalNames) {
									pageContext.setAttribute("medal_count", m.getScore(n).score);
									%>
									<td>${fn:escapeXml(medal_count)}</td>
									<%
								}
								pageContext.setAttribute("total_count", m.getScore("total").score);
								%>
								<td>${fn:escapeXml(total_count)}</td></tr>
								<%
							}
							%>
							</tbody>
							</table>
							</div>
              
              <div class="row"><h3>Player Medals:</h3></div>
							<div class = "row">
							<table class="table table-hover table-bordered">
							<thead>
							<tr><th></th>
							<%
							for (Entity game : games) {
								%>
								<th>
								<%
								pageContext.setAttribute("game_name", game.getProperty(Game.GAME_NAME));
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
									Medal m = playerMedals.get(g.getProperty(Game.GAME_ID));
									MedalScore ms = m.getScore(medalNames[i]);
									if (ms.displayName.equals("") || (ms.score == Integer.MAX_VALUE) || (ms.score == Integer.MIN_VALUE)) {
										pageContext.setAttribute("medal_score", "");
									} else {
										pageContext.setAttribute("medal_score", ms.displayName + ": " + Integer.toString(ms.score));
									}
									%><td>${fn:escapeXml(medal_score)}</td>
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
							<%
						}
						
						if (e.isTeamScore()) {
							%>
							<div class="row"><h3>Team Medals:</h3></div>
							<div class = "row">
							<table class="table table-hover table-bordered">
							<thead>
							<tr><th></th>
							<%
							for (Entity game : games) {
								%>
								<th>
								<%
								pageContext.setAttribute("game_name", game.getProperty(Game.GAME_NAME));
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
									Medal m = teamMedals.get(g.getProperty(Game.GAME_ID));
									MedalScore ms = m.getScore(medalNames[i]);
									if (ms.displayName.equals("") || (ms.score == Integer.MAX_VALUE) || (ms.score == Integer.MIN_VALUE)) {
										pageContext.setAttribute("medal_score", "");
									} else {
										pageContext.setAttribute("medal_score", ms.displayName + ": " + Integer.toString(ms.score));
									}
									%><td>${fn:escapeXml(medal_score)}</td>
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
							<%
						}
						
						if (e.isTeamScore()) {
							%>
              <div class="row"><h3>Team Scores:</h3></div>
              <div class = "row">
              <table class="table table-hover table-bordered">
              <thead>
              <tr><th>Team</th>
              <%
              for (Entity game : games) {
                %>
                <th>
                <%
                pageContext.setAttribute("game_name", game.getProperty(Game.GAME_NAME));
                %>
                ${fn:escapeXml(game_name)}</th>
                <%
              }
							%>
              </tr>
              </thead>
              <tbody>
              <%
              for (String tname : teams.keySet()) {
								pageContext.setAttribute("team_name", Player.humanize(tname));
								%>
								<tr><td>${fn:escapeXml(team_name)}</td>
								<%
								for (Entity game : games) {
									if (teams.get(tname).containsKey(game.getProperty(Game.GAME_ID))) {
										pageContext.setAttribute("team_score", teams.get(tname).get(game.getProperty(Game.GAME_ID)));
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
              <%
						}
						%>
            <div class="row"><h3>Player Scores:</h3></div>
            <div class = "row">
            <table class="table table-hover table-bordered">
            <thead>
            <tr><th>Player</th>
            <%
						if (e.usesTeams()) {
							%>
							<th>Team</th>
							<%
						}
            for (Entity game : games) {
              %>
              <th>
              <%
              pageContext.setAttribute("game_name", game.getProperty(Game.GAME_NAME));
              %>
              ${fn:escapeXml(game_name)}</th>
              <%
            }
          	%>
            </tr>
            </thead>
            <tbody>
            <%
						for (Entity dp : players) {
							pageContext.setAttribute("player_name", dp.getProperty(Player.PLAYER_NAME));
							pageContext.setAttribute("team_name", Player.humanize((String) dp.getProperty(Player.TEAM_NAME)));
							%>
							<tr><td>${fn:escapeXml(player_name)}</td>
              <%
							if (e.usesTeams()) {
								%>
                <td>${fn:escapeXml(team_name)}</td>
                <%
							}
							for (Entity game : games) {
								Integer ps = 
									(((Player) displayPlayers.get(dp.getProperty(Player.PLAYER_ID))).getScore(((Long) game.getProperty(Game.GAME_ID)).intValue()));
								if (ps == null) {
									pageContext.setAttribute("player_score", "");
								} else {
									pageContext.setAttribute("player_score", ps);
								}
								%>
								<td>${fn:escapeXml(player_score)}</td>
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