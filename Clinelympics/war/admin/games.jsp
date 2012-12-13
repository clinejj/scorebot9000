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
	Key settingsKey = KeyFactory.createKey(Settings.keyKind, Settings.keyName);
	Query query = new Query(Settings.entityKind, settingsKey);
	List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	if (!settings.isEmpty()) {
		Settings s = new Settings(settings.get(0));
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();
		if (user != null) {
			if (user.getNickname().equals(s.getAdmin())) {
				%>
    <div>
  <%
		pageContext.setAttribute("nameval", Game.gameNameName);
		pageContext.setAttribute("scoreval", Game.scoreTypeName);
	%>
    <form action="/games" method="post" class="form-inline">
      <label for="${fn:escapeXml(nameval)}">Game Name:</label><input type="text" name="${fn:escapeXml(nameval)}" />
      <label>Score Type:</label>
      <label class="radio">
        <input type="radio" name="${fn:escapeXml(scoreval)}" value="true" checked> High
      </label>
      <label class="radio">
        <input type="radio" name="${fn:escapeXml(scoreval)}" value="false"> Low
      </label>
      <input type="submit" value="Add Game" class="btn btn-primary"/>
    </form>
    </div>
  <div>
<%
    Key gameKey = KeyFactory.createKey(Game.keyKind, Game.keyName);
    query = new Query(Game.entityKind, gameKey).addSort(Game.gameIDName, Query.SortDirection.ASCENDING);
    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (games.isEmpty()) {
        %>
        <p class="text-error">There are no games</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>GameID</th><th>GameName</th><th>scoreType</th></tr>
        </thead><tbody>
        <%
        for (Entity game : games) {
			%>
            <tr>
            <%
            pageContext.setAttribute("game_id", game.getProperty(Game.gameIDName));
			pageContext.setAttribute("game_name", game.getProperty(Game.gameNameName));
			if ((Boolean) game.getProperty(Game.scoreTypeName)) {			
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
</tbody>
	</table>
  </div>
      <%
			}
		}
	}
	%>