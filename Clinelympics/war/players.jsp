<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
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

<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key playerKey = KeyFactory.createKey("Players", "playerList");
    Query query = new Query("player", playerKey).addSort("playerID", Query.SortDirection.DESCENDING);
    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(100));
    if (players.isEmpty()) {
        %>
        <p>There are no players</p>
        <%
    } else {
        %>
        <p>Players:</p>
        <table class="table table-hover">
        <tr><td>PlayerID</td><td>PlayerName</td><td>TeamName</td></tr>
        <%
        for (Entity player : players) {
			%>
            <tr>
            <%
            pageContext.setAttribute("player_id", player.getProperty("playerID"));
			pageContext.setAttribute("player_name", player.getProperty("playerName"));
			pageContext.setAttribute("team_name", player.getProperty("teamName"));
			%>
            <td>${fn:escapeXml(player_id)}</td>
            <td>${fn:escapeXml(player_name)}</td>
            <td>${fn:escapeXml(team_name)}</td>
			</tr>
            <%
        }
    }
%>
	</table>
    <form action="/register" method="post">
      <div>Player ID: <input type="text" name="playerID" /></div>
      <div>Player Name: <input type="text" name="playerName" /></div>
      <div>Team Name: <input type="text" name="teamName" /></div>
      <div><input type="submit" value="Add Player" /></div>
    </form>

  </body>
</html>