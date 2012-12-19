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
		Key settingsKey = KeyFactory.createKey(Settings.KEY_KIND, Settings.KEY_NAME);
		Query query = new Query(Settings.ENTITY_KIND, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		
		Key eventKey = KeyFactory.createKey(Event.KEY_KIND, Event.KEY_NAME);
		query = new Query(Event.ENTITY_KIND, eventKey).addSort(Event.EVENT_ID, Query.SortDirection.ASCENDING);
		Filter activeEvents = new FilterPredicate(Event.ARCHIVED_NAME, FilterOperator.EQUAL, false);
		query.setFilter(activeEvents);
		List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		%>
<!DOCTYPE html>
<html lang="en">
  <head>
  <% if (settings.isEmpty()) { %>
    	<title>Scores</title>
  <% } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.SITE_NAME)); %>
      <title>Scores - ${fn:escapeXml(site_name)}</title>
  <% } %>
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
				<div class="row"><h2 style="text-align: center;">Scores for ${fn:escapeXml(event_name)}</h2></div>
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
						System.out.println(scores.isEmpty());
						%>
						<div class="alert alert-error">Error accessing player scores.</div>
						<%
					} else if (!players.isEmpty() && !scores.isEmpty()) {		
						// Setup variables
						String[] medalNames = e.getEventMedals().split(",");
						HashMap<String, HashMap> teams = new HashMap<String, HashMap>();
						HashMap displayPlayers = new HashMap();
						
						// Get list of players for display
						for (Entity ePlayer : players) {
							displayPlayers.put(ePlayer.getProperty(Player.PLAYER_ID), new Player(ePlayer));
						}
						
						// Add scores to player display
						for (Entity eScore : scores) {
							((Player) displayPlayers.get(eScore.getProperty(Score.PLAYER_ID))).addScore(new Score(eScore));
						}
						
						// Generate teams
						for (Object dp : displayPlayers.values()) {
							// Setup teams
							if (!teams.containsKey(((Player) dp).getTeamName())) {
								teams.put(((Player) dp).getTeamName(), new HashMap<Object, Integer>());
							}
							
							// Store player scores
							for (Entity game : games) {
								Integer sc = ((Player) dp).getScore(((Long) game.getProperty(Game.GAME_ID)).intValue());
								// Add to medals
								if (sc != null) {
									if (teams.get(((Player) dp).getTeamName()).containsKey(game.getProperty(Game.GAME_ID))) {
										Integer ts = (Integer) teams.get(((Player) dp).getTeamName()).get(game.getProperty(Game.GAME_ID));
										teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.GAME_ID), sc + ts);
									} else {
										teams.get(((Player) dp).getTeamName()).put(game.getProperty(Game.GAME_ID), sc);
									}
								}	
							}
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
            <div class="row"><h3>Player Scores</h3></div>
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