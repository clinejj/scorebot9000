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
	Key settingsKey = KeyFactory.createKey(Settings.KEY_KIND, Settings.KEY_NAME);
	Query query = new Query(Settings.ENTITY_KIND, settingsKey);
	List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	if (!settings.isEmpty()) {
		Settings s = new Settings(settings.get(0));
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();
		if (user != null) {
			if (user.getNickname().equals(s.getAdmin())) {
				pageContext.setAttribute("fromval", Text.FROM);
				pageContext.setAttribute("bodyval", Text.BODY);
		%>
  <div id="text_response"></div>
  <div id="text_form">
  <form id="textForm" action="" class="form-inline">
  	From: <input type="text" name="${fn:escapeXml(fromval)}" maxlength="10" size="10"/>
  	Content: <input type="text" name="${fn:escapeXml(bodyval)}" maxlength="160" size="100" />
  	<input type="submit" value="Send" class="btn btn-primary" />
  </form>
    </div>
  <div id="text_table">
<%
    Key textKey = KeyFactory.createKey(Text.KEY_KIND, Text.KEY_NAME);
    query = new Query(Text.ENTITY_KIND, textKey).addSort(Text.SENT_DATE, Query.SortDirection.DESCENDING);
    List<Entity> texts = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (texts.isEmpty()) {
        %>
        <div class="row"><div class="alert alert-error">There are no texts</div></div>
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
            pageContext.setAttribute("date", text.getProperty(Text.SENT_DATE));
						pageContext.setAttribute("from", text.getProperty(Text.FROM));
						pageContext.setAttribute("body", text.getProperty(Text.BODY));
						pageContext.setAttribute("smsid", text.getProperty(Text.SMS_SID));
						pageContext.setAttribute("accountsid", text.getProperty(Text.ACCOUNT_SID));
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