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
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key textKey = KeyFactory.createKey(Text.keyKind, Text.keyName);
    Query query = new Query(Text.entityKind, textKey).addSort(Text.sentDateName, Query.SortDirection.DESCENDING);
    List<Entity> texts = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(100));
    if (texts.isEmpty()) {
        %>
        <p>There are no texts</p>
        <%
    } else {
        %>
        <table class="table table-hover">
        <tr><td>Date</td><td>From</td><td>Body</td><td>smsID</td><td>AccountSID</td></tr>
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
	</table>
  </div>
  <div calss="row">
  <form action="/inbound" method="post">
  	From: <input type="text" name="From" />
  	Content: <input type="text" name="Body" size="60" />
  	<input type="submit" value="Send text" />
  </form>
    </div>
	</div>
  </body>
</html>