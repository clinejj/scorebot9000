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
<%@ page import="com.csoft.clinelympics.Text" %>
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
				pageContext.setAttribute("fromval", Text.fromName);
				pageContext.setAttribute("bodyval", Text.bodyName);
		%>
  <div id="text_response"></div>
  <div id="text_form">
  <form id="textForm" action="" class="form-inline">
  	From: <input type="text" name="${fn:escapeXml(fromval)}" />
  	Content: <input type="text" name="${fn:escapeXml(bodyval)}" size="60" />
  	<input type="submit" value="Send text" class="btn btn-primary" />
  </form>
    </div>
  <div id="text_table">
<%
    Key textKey = KeyFactory.createKey(Text.keyKind, Text.keyName);
    query = new Query(Text.entityKind, textKey).addSort(Text.sentDateName, Query.SortDirection.DESCENDING);
    List<Entity> texts = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (texts.isEmpty()) {
        %>
        <p class="text-error">There are no texts</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <thead>
        <tr><th>Date</th><th>From</th><th>Body</th><th>smsID</th><th>AccountSID</th></tr></thead>
        <tbody>
        <%
        for (Entity text : texts) {
			%>
            <tr>
            <%
            pageContext.setAttribute("date", text.getProperty(Text.sentDateName));
						pageContext.setAttribute("from", text.getProperty(Text.fromName));
						pageContext.setAttribute("body", text.getProperty(Text.bodyName));
						pageContext.setAttribute("smsid", text.getProperty(Text.smsIDName));
						pageContext.setAttribute("accountsid", text.getProperty(Text.accountSIDName));
			%>
            <td>${fn:escapeXml(date)}</td>
            <td>${fn:escapeXml(from)}</td>
            <td>${fn:escapeXml(body)}</td>
            <td>${fn:escapeXml(smsid)}</td>
            <td>${fn:escapeXml(accountsid)}</td>
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