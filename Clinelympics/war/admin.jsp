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
  <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <a class="brand" href="/">Clinelympics</a>
      <ul class="nav">
        <li><a href="/">Home</a></li>
        <li><a href="/standings.jsp">Standings</a></li>
        <li><a href="/medals.jsp">Medals</a></li>
      </ul>
    </div>
  </div>
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
					pageContext.setAttribute("cur_event", s.getCurEventID());
					%>
          Hello, ${fn:escapeXml(admin_name)}! <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">(That's not me)</a>
          </div>
          <div class="row">
         	Your current number is: ${fn:escapeXml(admin_num)}
          </div>
          <div class="row">
          <p>The current event is: ${fn:escapeXml(cur_event)}</p>
          </div>
          <div class="row">
            <ul class="nav nav-tabs">
              <li class="active"><a href="#dashboard" data-toggle="tab">Dashboard</a></li>
              <li><a href="#event" data-toggle="tab">Events</a></li>
              <li><a href="#game" data-toggle="tab">Games</a></li>
              <li><a href="#player" data-toggle="tab">Players</a></li>
              <li><a href="#name" data-toggle="tab">Names</a></li>
              <li><a href="#score" data-toggle="tab">Scores</a></li>
              <li><a href="#text" data-toggle="tab">Texts</a></li>
            </ul>
          </div>
          <div class="row">
            <div class="tab-content">
              <div class="tab-pane active" id="dashboard">Coming Soon</div>
              <div class="tab-pane" id="event"><c:import url="/admin/events.jsp" /></div>
              <div class="tab-pane" id="game"><c:import url="/admin/games.jsp" /></div>
              <div class="tab-pane" id="player"><c:import url="/admin/players.jsp" /></div>
              <div class="tab-pane" id="name"><c:import url="/admin/names.jsp" /></div>
              <div class="tab-pane" id="score"><c:import url="/admin/scores.jsp" /></div>
              <div class="tab-pane" id="text"><c:import url="/admin/texts.jsp" /></div>
            </div>
          </div>
          <c:import url="/components/footer.html" />
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