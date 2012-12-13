<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Text" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!DOCTYPE html>
<html lang="en">
  <head>
  	<title>Texts - Clinelympics</title>
    <link type="text/css" rel="stylesheet" href="css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" href="css/bootstrap-responsive.min.css" />
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    <script type="application/javascript" src="js/bootstrap.min.js"></script>
  </head>

  <body>
  <div class="container">
  <div class="row">	<h2>Texts:</h2></div>
    <div class="row">
    <%
		pageContext.setAttribute("fromval", Text.fromName);
		pageContext.setAttribute("bodyval", Text.bodyName);
		%>
  <form action="/inbound" method="post" class="form-inline">
  	From: <input type="text" name="${fn:escapeXml(fromval)}" />
  	Content: <input type="text" name="${fn:escapeXml(bodyval)}" size="60" />
  	<input type="submit" value="Send text" class="btn btn-primary" />
  </form>
    </div>
  <div class="row">
<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key textKey = KeyFactory.createKey(Text.keyKind, Text.keyName);
    Query query = new Query(Text.entityKind, textKey).addSort(Text.sentDateName, Query.SortDirection.DESCENDING);
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
	</div>
  </body>
</html>