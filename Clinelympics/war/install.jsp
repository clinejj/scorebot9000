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
<%@ page import="com.csoft.clinelympics.Settings" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Clinelympics Installation</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link type="text/css" rel="stylesheet" href="css/bootstrap.min.css" />
    <link type="text/css" rel="stylesheet" href="css/bootstrap-responsive.min.css" />
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
    <script type="application/javascript" src="js/bootstrap.min.js"></script>
  </head>

  <body>
	<div class="container">
  <%
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Key settingsKey = KeyFactory.createKey(Settings.keyKind, Settings.keyName);
		Query query = new Query(Settings.entityKind, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		if (settings.isEmpty()) {
	%>
  <div class="row"><h2>Hello!</h2></div>
  <div class="row">
	<%
      UserService userService = UserServiceFactory.getUserService();
      User user = userService.getCurrentUser();
      if (user != null) {
        pageContext.setAttribute("user", user);
  %>
  <p>Thanks, ${fn:escapeXml(user.nickname)}! <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">(That's not me)</a></p> 
  </div>
  <div class="row"><p>Let's get started.</p></div>
  <div class="row">
      <%
		pageContext.setAttribute("admin", Settings.adminName);
		pageContext.setAttribute("adminnum", Settings.adminNumName);
		pageContext.setAttribute("curevent", Settings.curEventName);
		%>
  <form action="/install" method="post" class="form-horizontal">
    <div class="control-group">
    <div class="controls">
  		<input type="hidden" name="${fn:escapeXml(admin)}" value="${fn:escapeXml(user.nickname)}"/>
    </div>
    </div>
    <div class="control-group">
      <label class="control-label" for="${fn:escapeXml(adminnum)}">Phone number?</label>
      <div class="controls">
        <input type="text" id="${fn:escapeXml(adminnum)}" name="${fn:escapeXml(adminnum)}" placeholder="1234567890">
      </div>
    </div>
    <div class="control-group">
      <div class="controls">
        10 digits, no extra characters. This is used to recognize you via the text interface.
      </div>
    </div>
    <div class="control-group">
      <div class="controls">
        <button type="submit" class="btn btn-primary">Install</button>
      </div>
    </div>
  </form>
  </div>
  <%
      } else {
  %>
  <p>Please <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">sign in</a> to begin.</p>
  </div>
  <%
      }
		} else {
  %>
  <div class="row">
  Site has already been installed. <a href="/">Return home</a>
  </div>
  <%
		}
		%>
  </body>
</html>