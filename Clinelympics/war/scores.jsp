<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Score" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!DOCTYPE html>
<html lang="en">
  <head>
  	<title>Scores - Clinelympics</title>
    <link type="text/css" rel="stylesheet" href="css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" href="css/bootstrap-responsive.min.css" />
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    <script type="application/javascript" src="js/bootstrap.min.js"></script>
  </head>

  <body>
  <div class="container">
  <div class="row">	<h2>Scores:</h2></div>
    <div class="row">
    <%
		pageContext.setAttribute("idval", Score.playerIDName);
		pageContext.setAttribute("nameval", Score.gameIDName);
		pageContext.setAttribute("scoreval", Score.playerScoreName);
		%>
    <form action="/score" method="post" class="form-inline">
      Player ID: <input type="text" name="${fn:escapeXml(idval)}" />
      GameID: <input type="text" name="${fn:escapeXml(nameval)}" />
      Score: <input type="text" name="${fn:escapeXml(scoreval)}" />
      <input type="submit" value="Add Score" class="btn btn-primary"/>
    </form>
    </div>
  <div class="row">
<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key scoreKey = KeyFactory.createKey(Score.keyKind, Score.keyName);
    Query query = new Query(Score.entityKind, scoreKey).addSort(Score.dateName, Query.SortDirection.DESCENDING);
    List<Entity> scores = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (scores.isEmpty()) {
        %>
        <p class="text-error">There are no scores</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>Date</td><th>Player</th><th>Game</th><th>Score</th></tr></thead>
        <tbody>
        <%
        for (Entity score : scores) {
			%>
            <tr>
            <%
            pageContext.setAttribute("player_id", score.getProperty(Score.playerIDName));
			pageContext.setAttribute("game_id", score.getProperty(Score.gameIDName));
			pageContext.setAttribute("player_score", score.getProperty(Score.playerScoreName));
			pageContext.setAttribute("date", score.getProperty(Score.dateName));
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
</tbody>
	</table>
  </div>
	</div>
  </body>
</html>