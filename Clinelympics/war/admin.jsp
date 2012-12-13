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
<%@ page import="com.csoft.clinelympics.Event" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Admin - Clinelympics</title>
    <c:import url="/components/head.html" />
  </head>

  <body>
  <c:import url="/components/nav.html" />
	<div class="container">
  <%
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Key settingsKey = KeyFactory.createKey(Settings.keyKind, Settings.keyName);
		Query query = new Query(Settings.entityKind, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		if (settings.isEmpty()) {
		%>
			<div class="row"><p class="text-error">Please <a href="/install.jsp">install</a> Clinelympics.</p></div>
		<%
		} else {
			Settings s = new Settings(settings.get(0));
			UserService userService = UserServiceFactory.getUserService();
      User user = userService.getCurrentUser();
			if (user != null) {
			%>
        <div class="row"><h2>Admin Panel</h2></div>
        <div class="row">
				<%
				if (user.getNickname().equals(s.getAdmin())) {
					pageContext.setAttribute("admin_name", s.getAdmin());
					pageContext.setAttribute("admin_num", s.getAdminNum());
					%>
          Hello, ${fn:escapeXml(admin_name)}! <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">(That's not me)</a>
          </div>
          <div class="row">
          <p>Your current number is: ${fn:escapeXml(admin_num)}</p>
          </div>
          <div class="row">
            <ul class="nav nav-tabs">
              <li class="active"><a href="#home" data-toggle="tab">Dashboard</a></li>
              <li><a href="#events" data-toggle="tab">Events</a></li>
              <li><a href="#games" data-toggle="tab">Games</a></li>
              <li><a href="#players" data-toggle="tab">Players</a></li>
              <li><a href="#names" data-toggle="tab">Names</a></li>
              <li><a href="#scores" data-toggle="tab">Scores</a></li>
              <li><a href="#texts" data-toggle="tab">Texts</a></li>
            </ul>
          </div>
          <div class="row">
            <div class="tab-content">
              <div class="tab-pane active" id="home">...</div>
              <div class="tab-pane" id="events"><c:import url="/admin/events.jsp" /></div>
              <div class="tab-pane" id="games"><c:import url="/admin/games.jsp" /></div>
              <div class="tab-pane" id="players"><c:import url="/admin/players.jsp" /></div>
              <div class="tab-pane" id="names"><c:import url="/admin/names.jsp" /></div>
              <div class="tab-pane" id="scores"><c:import url="/admin/scores.jsp" /></div>
              <div class="tab-pane" id="texts"><c:import url="/admin/texts.jsp" /></div>
            </div>
          </div>
				<%
        } else {
        %>
        	<div class="row">
          <p class="text-error">You do not have permission to view this page.    </p><a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">Logout</a>
          </div>
          <%
      	}
			} else {
			%>
      <div class="row">
				<h2>Admin Panel</h2>      
      </div>
      <div class="row">
      <p>Please <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">sign in</a>.</p>
      </div>
			<%
			}
		}
		%>
  </body>
</html>