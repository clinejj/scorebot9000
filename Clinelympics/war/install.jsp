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
  	<div class="control">
  		<input type="hidden" name="${fn:escapeXml(admin)}" value="${fn:escapeXml(user.nickname)}"/>
    </div>
    </div>
    <div class="control-group">
      <label class="control-label" for="${fn:escapeXml(adminnum)}">What's your phone number (10 digits, no extra characters): </label>
      <div class="control">
        <input type="text" name="${fn:escapeXml(adminnum)}" placeholder="1234567890" />
      </div>
    </div>
    <div class="control-group">
  	<label class="control-label" for="${fn:escapeXml(curevent)}">Would you like to automatically create an event?: </label>
    <div class="control">
      <label class="radio">
          <input type="radio" name="${fn:escapeXml(curevent)}" value="1" checked> Yes
        </label>
        <label class="radio">
          <input type="radio" name="${fn:escapeXml(curevent)}" value="0"> No
        </label>
    </div>
    </div>
    <div class="control-group">
    	<div class="control">
  			<input type="submit" value="Submit" class="btn btn-primary" />
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
  %>
  </body>
</html>