<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Score" %>
<%@ page import="com.csoft.clinelympics.Settings" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<%
	DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
	Key settingsKey = KeyFactory.createKey(Settings.keyKind, Settings.keyName);
	Query query = new Query(Settings.entityKind, settingsKey);
	List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	if (!settings.isEmpty()) {
		Settings s = new Settings(settings.get(0));
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();
		if (user != null) {
			if (user.getNickname().equals(s.getAdmin())) {
				pageContext.setAttribute("idval", Score.playerIDName);
				pageContext.setAttribute("nameval", Score.gameIDName);
				pageContext.setAttribute("scoreval", Score.playerScoreName);
				pageContext.setAttribute("eventval", Score.playerScoreName);
				pageContext.setAttribute("user_email", s.getAdmin()); 
				pageContext.setAttribute("type_val", Score.entityKind);
		%>
    <div id="score_response"></div>
    <div id="score_form">
    <form action="" id="addScoreForm" class="form-inline">
      Player ID: <input type="text" name="${fn:escapeXml(idval)}" />
      Game ID: <input type="text" name="${fn:escapeXml(nameval)}" />
      Score: <input type="text" name="${fn:escapeXml(scoreval)}" />
      Event ID: <input type="text" name="${fn:escapeXml(eventval)}" />
      <input type="hidden" value="${fn:escapeXml(user_email)}" id="userEmail"/>
    	<input type="hidden" id="scoreType" name="type" value="${fn:escapeXml(type_val)}" />
      <input type="submit" value="Add Score" class="btn btn-primary"/>
    </form>
    </div>
  <div id="score_table">
<%
    Key scoreKey = KeyFactory.createKey(Score.keyKind, Score.keyName);
    query = new Query(Score.entityKind, scoreKey).addSort(Score.dateName, Query.SortDirection.DESCENDING);
    List<Entity> scores = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (scores.isEmpty()) {
        %>
        <p class="text-error">There are no scores</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>Date</td><th>Player</th><th>Game</th><th>Event</th><th>Score</th></tr></thead>
        <tbody>
        <%
        for (Entity score : scores) {
			%>
            <tr>
            <%
            pageContext.setAttribute("player_id", score.getProperty(Score.playerIDName));
						pageContext.setAttribute("game_id", score.getProperty(Score.gameIDName));
						pageContext.setAttribute("player_score", score.getProperty(Score.playerScoreName));
						pageContext.setAttribute("event_id", score.getProperty(Score.eventIDName));
						pageContext.setAttribute("date", score.getProperty(Score.dateName));
						%>
            <td>${fn:escapeXml(date)}</td>
            <td>${fn:escapeXml(player_id)}</td>
            <td>${fn:escapeXml(game_id)}</td>
            <td>${fn:escapeXml(event_id)}</td>
            <td>${fn:escapeXml(player_score)}</td>
			</tr>
            <%
        }
    }
%>
</tbody>
	</table>
  </div>
    <%
			}
		}
	}
	%>