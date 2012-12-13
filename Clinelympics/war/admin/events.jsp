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
		pageContext.setAttribute("nameval", Event.eventNameName);
		pageContext.setAttribute("medalval", Event.medalsName);
	%>
    <form action="/events" method="post" class="form-inline">
      <label for="${fn:escapeXml(nameval)}">Event Name:</label><input type="text" name="${fn:escapeXml(nameval)}" />
      <label for="${fn:escapeXml(medalval)}">Medals:</label><input type="text" name="${fn:escapeXml(medalval)}" placeholder="Gold,Silver,Bronze"/>
      Medals must be comma separated, best to worst
      <input type="submit" value="Add Event" class="btn btn-primary"/>
    </form>
    </div>
<div>
<%
    Key eventKey = KeyFactory.createKey(Event.keyKind, Event.keyName);
    query = new Query(Event.entityKind, eventKey).addSort(Event.eventIDName, Query.SortDirection.ASCENDING);
    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (events.isEmpty()) {
        %>
        <p class="text-error">There are no events</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>eventID</th><th>eventName</th><th>medalsName</th><th>isArchived</th></tr>
        </thead><tbody>
        <%
        for (Entity event : events) {
			%>
            <tr>
            <%
            pageContext.setAttribute("event_id", event.getProperty(Event.eventIDName));
						pageContext.setAttribute("event_name", event.getProperty(Event.eventNameName));
						pageContext.setAttribute("medals_name", event.getProperty(Event.medalsName));
						if ((Boolean) event.getProperty(Event.archivedName)) {			
							pageContext.setAttribute("archived", "Yes");
						}
			%>
            <td>${fn:escapeXml(event_id)}</td>
            <td>${fn:escapeXml(event_name)}</td>
            <td>${fn:escapeXml(medals_name)}</td>
            <td>${fn:escapeXml(archived)}</td>
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