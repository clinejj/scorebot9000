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
				pageContext.setAttribute("nameval", Event.eventNameName);
				pageContext.setAttribute("medalval", Event.medalsName);
				pageContext.setAttribute("archiveval", Event.archivedName);
				pageContext.setAttribute("activeval", Event.activeName);
				pageContext.setAttribute("user_email", s.getAdmin()); 
				pageContext.setAttribute("type_val", Event.entityKind);
	%>
  <div id="event_response"></div>
  <div id="event_form">
    <form action="" id="addEventForm" class="form-inline">
      <label for="${fn:escapeXml(nameval)}">Event Name:</label><input type="text" name="${fn:escapeXml(nameval)}" maxlength="50" size="50" />
      <label for="${fn:escapeXml(medalval)}">Medals:</label><input type="text" name="${fn:escapeXml(medalval)}" id="eventNameIn" placeholder="Gold,Silver,Bronze" data-placement="top" data-original-title="Medals must be comma separated, best to worst" maxlength="70" size="70"/>
      <label class="checkbox">Active:<input type="checkbox" name="${fn:escapeXml(activeval)}" value="true"></label>
			<label class="checkbox">Archive:<input type="checkbox" name="${fn:escapeXml(archiveval)}" value="true"></label> 
      <input type="hidden" value="${fn:escapeXml(user_email)}" id="userEmail"/>
    	<input type="hidden" id="eventType" name="type" value="${fn:escapeXml(type_val)}" />
      <input type="submit" value="Add" class="btn btn-primary"/>
    </form>
    </div>
<div id="event_table">
<%
    Key eventKey = KeyFactory.createKey(Event.keyKind, Event.keyName);
    query = new Query(Event.entityKind, eventKey).addSort(Event.eventIDName, Query.SortDirection.DESCENDING);
    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (events.isEmpty()) {
        %>
        <p class="text-error">There are no events</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>EventID</th><th>EventName</th><th>MedalsName</th><th>isActive</th><th>isArchived</th></tr>
        </thead><tbody>
        <%
        for (Entity event : events) {
			%>
            <tr>
            <%
            pageContext.setAttribute("event_id", event.getProperty(Event.eventIDName));
						pageContext.setAttribute("event_name", event.getProperty(Event.eventNameName));
						pageContext.setAttribute("medals_name", event.getProperty(Event.medalsName));
						if ((Boolean) event.getProperty(Event.activeName)) {			
							pageContext.setAttribute("active", "Yes");
						} else {
							pageContext.setAttribute("active", "");
						}
						if ((Boolean) event.getProperty(Event.archivedName)) {			
							pageContext.setAttribute("archived", "Yes");
						} else {
							pageContext.setAttribute("archived", "");
						}
			%>
            <td>${fn:escapeXml(event_id)}</td>
            <td>${fn:escapeXml(event_name)}</td>
            <td>${fn:escapeXml(medals_name)}</td>
            <td>${fn:escapeXml(active)}</td>
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