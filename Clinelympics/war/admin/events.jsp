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
<%@ page import="com.csoft.clinelympics.Event" %>
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
				pageContext.setAttribute("nameval", Event.EVENT_NAME);
				pageContext.setAttribute("medalval", Event.MEDALS_NAME);
				pageContext.setAttribute("archiveval", Event.ARCHIVED_NAME);
				pageContext.setAttribute("activeval", Event.ACTIVE_NAME);
				pageContext.setAttribute("user_email", s.getAdmin()); 
				pageContext.setAttribute("type_val", Event.ENTITY_KIND);
				pageContext.setAttribute("team_val", Event.TEAMSCORE_NAME);
				pageContext.setAttribute("team_sup_val", Event.TEAM_SUPPORT);
	%>
  <div id="event_response"></div>
  <div id="event_form">
    <form action="" id="addEventForm" class="form-inline">
      <label for="${fn:escapeXml(nameval)}">Event Name:</label><input type="text" name="${fn:escapeXml(nameval)}" maxlength="50" size="40" />
      <label for="${fn:escapeXml(medalval)}">Medals:</label><input type="text" name="${fn:escapeXml(medalval)}" id="eventMedalIn" placeholder="Gold,Silver,Bronze" data-placement="top" data-original-title="Medals must be comma separated, best to worst" maxlength="60" size="50"/>
      <label class="checkbox">Active<input type="checkbox" name="${fn:escapeXml(activeval)}" value="true"></label>
			<label class="checkbox">Archive<input type="checkbox" name="${fn:escapeXml(archiveval)}" value="true"></label>
      <label class="checkbox">Teams<input type="checkbox" name="${fn:escapeXml(team_sup_val)}" value="true"></label> 
      <label class="radio" id="teamRadio" data-placement="top" data-original-title="Combine player scores, medals won by team">
        <input type="radio" name="${fn:escapeXml(team_val)}" value="true"> Team
      </label>
      <label class="radio" id="playerRadio" data-placement="top" data-original-title="Medals won by player">
        <input type="radio" name="${fn:escapeXml(team_val)}" value="false" checked> Player
      </label>
      <input type="hidden" value="${fn:escapeXml(user_email)}" id="userEmail"/>
    	<input type="hidden" id="eventType" name="type" value="${fn:escapeXml(type_val)}" />
      <input type="submit" value="Add" class="btn btn-primary"/>
    </form>
    </div>
<div id="event_table">
<%
    Key eventKey = KeyFactory.createKey(Event.KEY_KIND, Event.KEY_NAME);
    query = new Query(Event.ENTITY_KIND, eventKey).addSort(Event.EVENT_ID, Query.SortDirection.DESCENDING);
    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (events.isEmpty()) {
        %>
        <div class="alert alert-error">There are no events</div>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>EventID</th><th>EventName</th><th>MedalsName</th><th>isActive</th><th>isArchived</th><th>Teams?</th><th>Score Type</th></tr>
        </thead><tbody>
        <%
        for (Entity event : events) {
			%>
            <tr>
            <%
            pageContext.setAttribute("event_id", event.getProperty(Event.EVENT_ID));
						pageContext.setAttribute("event_name", event.getProperty(Event.EVENT_NAME));
						pageContext.setAttribute("medals_name", event.getProperty(Event.MEDALS_NAME));
						if ((Boolean) event.getProperty(Event.ACTIVE_NAME)) {			
							pageContext.setAttribute("active", "Yes");
						} else {
							pageContext.setAttribute("active", "");
						}
						if ((Boolean) event.getProperty(Event.ARCHIVED_NAME)) {			
							pageContext.setAttribute("archived", "Yes");
						} else {
							pageContext.setAttribute("archived", "");
						}
						if ((Boolean) event.getProperty(Event.TEAM_SUPPORT)) {			
							pageContext.setAttribute("teamsupport", "Yes");
						} else {
							pageContext.setAttribute("teamsupport", "");
						}
						if ((Boolean) event.getProperty(Event.TEAMSCORE_NAME)) {			
							pageContext.setAttribute("teamscore", "Team");
						} else {
							pageContext.setAttribute("teamscore", "Player");
						}
			%>
            <td>${fn:escapeXml(event_id)}</td>
            <td>${fn:escapeXml(event_name)}</td>
            <td>${fn:escapeXml(medals_name)}</td>
            <td>${fn:escapeXml(active)}</td>
            <td>${fn:escapeXml(archived)}</td>
            <td>${fn:escapeXml(teamsupport)}</td>
            <td>${fn:escapeXml(teamscore)}</td>
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