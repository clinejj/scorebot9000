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
  	<title>Games - Clinelympics</title>
    <link type="text/css" rel="stylesheet" href="css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" href="css/bootstrap-responsive.min.css" />
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    <script type="application/javascript" src="js/bootstrap.min.js"></script>
  </head>

  <body>

<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key gameKey = KeyFactory.createKey("Games", "gameList");
    Query query = new Query("game", gameKey).addSort("gameName", Query.SortDirection.DESCENDING);
    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(100));
    if (games.isEmpty()) {
        %>
        <p>There are no games</p>
        <%
    } else {
        %>
        <p>Games:</p>
        <table class="table table-hover">
        <tr><td>GameID</td><td>GameName</td><td>scoreType</td></tr>
        <%
        for (Entity game : games) {
			%>
            <tr>
            <%
            pageContext.setAttribute("game_id", game.getProperty("gameID"));
			pageContext.setAttribute("game_name", game.getProperty("gameName"));
			if ((Boolean) game.getProperty("scoreType")) {			
				pageContext.setAttribute("score_type", "high");
			} else {
				pageContext.setAttribute("score_type", "low");
			}
			%>
            <td>${fn:escapeXml(game_id)}</td>
            <td>${fn:escapeXml(game_name)}</td>
            <td>${fn:escapeXml(score_type)}</td>
			</tr>
            <%
        }
    }
%>
	</table>
    <form action="/games" method="post">
      <div>Game ID: <input type="text" name="gameID" /></div>
      <div>Game Name: <input type="text" name="gameName" /></div>
      <div>Score Type: <input type="radio" name="scoreType" value="true" checked> High
	  <input type="radio" name="scoreType" value="false"> Low</div>
      <div><input type="submit" value="Add Game" /></div>
    </form>

  </body>
</html>