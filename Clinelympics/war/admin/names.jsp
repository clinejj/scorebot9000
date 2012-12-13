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
<%@ page import="com.csoft.clinelympics.Name" %>
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
<% pageContext.setAttribute("nameval", Name.nameStr); %>
  <form action="/names" method="post" class="form-inline">
    Name: <input type="text" name="${fn:escapeXml(nameval)}" />
    <input type="submit" value="Add Name" class="btn btn-primary"/>
  </form>
  </div>
  <div>
<%
    Key nameKey = KeyFactory.createKey(Name.keyKind, Name.keyName);
    query = new Query(Name.entityKind, nameKey).addSort(Name.nameStr, Query.SortDirection.ASCENDING);
    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (names.isEmpty()) {
        %>
        <p class="text-error">There are no names</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>Name</th><th>rnd</th><th>isUsed</th></tr></thead>
        <tbody>
        <%
        for (Entity name : names) {
			%>
            <tr>
            <%
            pageContext.setAttribute("name", name.getProperty(Name.nameStr));
						pageContext.setAttribute("rnd", name.getProperty(Name.rndStr));
						if ((Boolean) name.getProperty(Name.usedStr)) {			
							pageContext.setAttribute("used", "Yes");
						} else {
							pageContext.setAttribute("used", "");
						}
						%>
            <td>${fn:escapeXml(name)}</td>
            <td>${fn:escapeXml(rnd)}</td>
            <td>${fn:escapeXml(used)}</td>
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