<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
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
<%@ page import="com.csoft.clinelympics.Event" %>
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
				pageContext.setAttribute("user_email", s.getAdmin());
				
				Key eventKey = KeyFactory.createKey(Event.KEY_KIND, Event.KEY_NAME);
				query = new Query(Event.ENTITY_KIND, eventKey).addSort(Event.EVENT_ID, Query.SortDirection.ASCENDING);
				List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				if (events.isEmpty()) { 
				%>
				<div id="event_err_box" class="alert alert-error">
					<button type="button" class="close" data-dismiss="alert">&times;</button>
					<strong>Hey!</strong> You don't have any events setup. Click on the events tab to create one.
				</div>
					<%
				}
				
				Key gameKey = KeyFactory.createKey(Game.KEY_KIND, Game.KEY_NAME);
				query = new Query(Game.ENTITY_KIND, gameKey).addSort(Game.GAME_ID, Query.SortDirection.ASCENDING);
				Filter feID = new FilterPredicate(Game.EVENT_ID, FilterOperator.EQUAL, s.getCurEventID());
				query.setFilter(feID);
				List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				if (games.isEmpty() && (s.getCurEventID() != -1)) {
				%>
        <div id="game_err_box" class="alert">
					<button type="button" class="close" data-dismiss="alert">&times;</button>
					<strong>Hey!</strong> Your current event doesn't have any games. Create one on the game tab.
				</div>
        <%
				}
			}
		}
	}
	%>
	<script type="application/javascript" src="js/table-magic.js"></script>