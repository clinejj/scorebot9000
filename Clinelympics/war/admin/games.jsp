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
<%@ page import="com.csoft.clinelympics.Game" %>
<%@ page import="com.csoft.clinelympics.Settings" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<%
	DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
	Key settingsKey = KeyFactory.createKey(Settings.KEY_KIND, Settings.KEY_NAME);
	Query query = new Query(Settings.ENTITY_KIND, settingsKey);
	List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	if (!settings.isEmpty()) {
		Settings s = new Settings(settings.get(0));
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();
		if (user != null) {
			if (user.getNickname().equals(s.getAdmin())) {
				pageContext.setAttribute("eventval", Game.EVENT_ID);
				pageContext.setAttribute("nameval", Game.GAME_NAME);
				pageContext.setAttribute("scoreval", Game.SCORE_TYPE);
				pageContext.setAttribute("user_email", s.getAdmin()); 
				pageContext.setAttribute("type_val", Game.ENTITY_KIND);
	%>
  <div id="game_response"></div>
  <div id="game_form">
    <form action="" id="addGameForm" class="form-inline">
    	<label for="${fn:escapeXml(eventval)}">Event ID:</label><input type="text" name="${fn:escapeXml(eventval)}" maxlength="3" size="3" />
      <label for="${fn:escapeXml(nameval)}">Game Name:</label><input type="text" name="${fn:escapeXml(nameval)}" maxlength="40" size="40"/>
      <label>Score Type:</label>
      <label class="radio">
        <input type="radio" name="${fn:escapeXml(scoreval)}" value="true" checked> High
      </label>
      <label class="radio">
        <input type="radio" name="${fn:escapeXml(scoreval)}" value="false"> Low
      </label>
      <input type="hidden" value="${fn:escapeXml(user_email)}" id="userEmail"/>
    	<input type="hidden" id="gameType" name="type" value="${fn:escapeXml(type_val)}" />
      <input type="submit" value="Add" class="btn btn-primary"/>
    </form>
    </div>
  <div id="game_table">
<%
    Key gameKey = KeyFactory.createKey(Game.KEY_KIND, Game.KEY_NAME);
    query = new Query(Game.ENTITY_KIND, gameKey).addSort(Game.EVENT_ID, Query.SortDirection.DESCENDING);
		query.addSort(Game.GAME_ID, Query.SortDirection.DESCENDING);
    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (games.isEmpty()) {
        %>
        <div class="alert alert-error">There are no games</div>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>EventID</th><th>GameID</th><th>GameName</th><th>scoreType</th></tr>
        </thead><tbody>
        <%
        for (Entity game : games) {
			%>
            <tr>
            <%
						pageContext.setAttribute("event_id", game.getProperty(Game.EVENT_ID));
            pageContext.setAttribute("game_id", game.getProperty(Game.GAME_ID));
						pageContext.setAttribute("game_name", game.getProperty(Game.GAME_NAME));
						if ((Boolean) game.getProperty(Game.SCORE_TYPE)) {			
							pageContext.setAttribute("score_type", "high");
						} else {
							pageContext.setAttribute("score_type", "low");
						}
						%>
            <td>${fn:escapeXml(event_id)}</td>
            <td>${fn:escapeXml(game_id)}</td>
            <td>${fn:escapeXml(game_name)}</td>
            <td>${fn:escapeXml(score_type)}</td>
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