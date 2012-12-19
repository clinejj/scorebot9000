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
	Key settingsKey = KeyFactory.createKey(Settings.KEY_KIND, Settings.KEY_NAME);
	Query query = new Query(Settings.ENTITY_KIND, settingsKey);
	List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	if (!settings.isEmpty()) {
		Settings s = new Settings(settings.get(0));
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();
		if (user != null) {
			if (user.getNickname().equals(s.getAdmin())) {
				pageContext.setAttribute("nameval", Name.NAME);
				pageContext.setAttribute("user_email", s.getAdmin()); 
			pageContext.setAttribute("type_val", Name.ENTITY_KIND); %>
  <div id="name_response"></div>
  <div id="name_form">
  <form id="addNameForm" action="" class="form-inline">
    Name: <input type="text" name="${fn:escapeXml(nameval)}" maxlength="80" size="80" />
    <input type="hidden" value="${fn:escapeXml(user_email)}" id="userEmail"/>
    <input type="hidden" id="nameType" name="type" value="${fn:escapeXml(type_val)}" />
    <input type="submit" value="Add" class="btn btn-primary"/>
  </form>
  </div>
  <div id="nametable">
<%
    Key nameKey = KeyFactory.createKey(Name.KEY_KIND, Name.KEY_NAME);
    query = new Query(Name.ENTITY_KIND, nameKey).addSort(Name.NAME, Query.SortDirection.ASCENDING);
    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (names.isEmpty()) {
        %>
        <div class="alert alert-error">There are no names</div>
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
            pageContext.setAttribute("name", name.getProperty(Name.NAME));
						pageContext.setAttribute("rnd", name.getProperty(Name.RND));
						if ((Boolean) name.getProperty(Name.USED)) {			
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