<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Name" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!DOCTYPE html>
<html lang="en">
  <head>
  	<title>Names - Clinelympics</title>
    <link type="text/css" rel="stylesheet" href="css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" href="css/bootstrap-responsive.min.css" />
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    <script type="application/javascript" src="js/bootstrap.min.js"></script>
  </head>

  <body>
  <div class="container">
  <div class="row">	<h2>Names:</h2></div>
  <div class="row">
<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    Key nameKey = KeyFactory.createKey(Name.keyKind, Name.keyName);
    Query query = new Query(Name.entityKind, nameKey).addSort(Name.nameStr, Query.SortDirection.DESCENDING);
    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    if (names.isEmpty()) {
        %>
        <p class="text-error">There are no scores</p>
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
  <div calss="row">
    <form action="/names" method="post">
      <div>Name: <input type="text" name="nameval" /></div>
      <div><input type="submit" value="Add Name" class="btn btn-primary"/></div>
    </form>
    </div>
	</div>
  </body>
</html>