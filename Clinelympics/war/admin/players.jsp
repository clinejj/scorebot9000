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
<%@ page import="com.csoft.clinelympics.Player" %>
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
				pageContext.setAttribute("idval", Player.playerIDName);
				pageContext.setAttribute("nameval", Player.playerNameName);
				pageContext.setAttribute("teamval", Player.teamNameName);
				pageContext.setAttribute("user_email", s.getAdmin()); 
				pageContext.setAttribute("type_val", Player.entityKind);
		%>
    <div id="player_response"></div>
  	<div id="player_form">
    <form action="" id="addPlayerForm" class="form-inline">
      Player ID: <input type="text" name="${fn:escapeXml(idval)}" />
      Player Name: <input type="text" name="${fn:escapeXml(nameval)}" />
      Team Name: <input type="text" name="${fn:escapeXml(teamval)}" />
      <input type="hidden" value="${fn:escapeXml(user_email)}" id="userEmail"/>
    	<input type="hidden" id="playerType" name="type" value="${fn:escapeXml(type_val)}" />
      <input type="submit" value="Add Player" class="btn btn-primary" />
    </form>
    </div>
  <div id="player_table">
<%
    Key playerKey = KeyFactory.createKey(Player.keyKind, Player.keyName);
    query = new Query(Player.entityKind, playerKey).addSort(Player.playerIDName, Query.SortDirection.DESCENDING);
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
    <%
			}
		}
	}
	%>