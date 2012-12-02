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

<html>
  <head>
    <link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
  </head>

  <body>

<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key scoreKey = KeyFactory.createKey("Scores", "scoreList");
    // Run an ancestor query to ensure we see the most up-to-date
    // view of the Greetings belonging to the selected Guestbook.
    Query query = new Query("score", scoreKey).addSort("date", Query.SortDirection.DESCENDING);
    List<Entity> scores = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(10));
    if (scores.isEmpty()) {
        %>
        <p>There are no scores</p>
        <%
    } else {
        %>
        <p>Scores:</p>
        <table cellspacing="10">
        <tr><td>Date</td><td>Player</td><td>Game</td><td>Score</td></tr>
        <%
        for (Entity score : scores) {
			%>
            <tr>
            <%
            pageContext.setAttribute("player_id", score.getProperty("playerID"));
			pageContext.setAttribute("game_id", score.getProperty("gameID"));
			pageContext.setAttribute("player_score", score.getProperty("playerScore"));
			pageContext.setAttribute("date", score.getProperty("date"));
			%>
            <td>${fn:escapeXml(date)}</td>
            <td>${fn:escapeXml(player_id)}</td>
            <td>${fn:escapeXml(game_id)}</td>
            <td>${fn:escapeXml(player_score)}</td>
			</tr>
            <%
        }
    }
%>
	</table>
    <form action="/score" method="post">
      <div>Player ID: <input type="text" name="playerID" /></div>
      <div>GameID: <input type="text" name="gameID" /></div>
      <div>Score: <input type="text" name="playerScore" /></div>
      <div><input type="submit" value="Add Score" /></div>
    </form>

  </body>
</html>