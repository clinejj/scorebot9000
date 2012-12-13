<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Player" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!DOCTYPE html>
<html lang="en">
  <head>
  	<title>Players - Clinelympics</title>
    <link type="text/css" rel="stylesheet" href="css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" href="css/bootstrap-responsive.min.css" />
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    <script type="application/javascript" src="js/bootstrap.min.js"></script>
  </head>

  <body>
  <div class="container">
  <div class="row">	<h2>Players:</h2></div>
    <div class="row">
    <%
		pageContext.setAttribute("idval", Player.playerIDName);
		pageContext.setAttribute("nameval", Player.playerNameName);
		pageContext.setAttribute("teamval", Player.teamNameName);
		%>
    <form action="/register" method="post" class="form-inline">
      Player ID: <input type="text" name="${fn:escapeXml(idval)}" />
      Player Name: <input type="text" name="${fn:escapeXml(nameval)}" />
      Team Name: <input type="text" name="${fn:escapeXml(teamval)}" />
      <input type="submit" value="Add Player" class="btn btn-primary" />
    </form>
    </div>
  <div class="row">
<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key playerKey = KeyFactory.createKey(Player.keyKind, Player.keyName);
    Query query = new Query(Player.entityKind, playerKey).addSort(Player.playerIDName, Query.SortDirection.DESCENDING);
    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (players.isEmpty()) {
        %>
        <p class="text-error">There are no players</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>PlayerID</th><th>PlayerName</th><th>TeamName</th></tr>
        </thead><tbody>
        <%
        for (Entity player : players) {
			%>
            <tr>
            <%
            pageContext.setAttribute("player_id", player.getProperty(Player.playerIDName));
			pageContext.setAttribute("player_name", player.getProperty(Player.playerNameName));
			pageContext.setAttribute("team_name", player.getProperty(Player.teamNameName));
			%>
            <td>${fn:escapeXml(player_id)}</td>
            <td>${fn:escapeXml(player_name)}</td>
            <td>${fn:escapeXml(team_name)}</td>
			</tr>
            <%
        }
    }
%>
</tbody>
	</table>
  </div>
	</div>
  </body>
</html>