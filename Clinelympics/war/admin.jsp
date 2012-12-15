<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.datastore.Query.Filter" %>
<%@ page import="com.google.appengine.api.datastore.Query.FilterPredicate" %>
<%@ page import="com.google.appengine.api.datastore.Query.FilterOperator" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.csoft.clinelympics.Settings" %>
<%@ page import="com.csoft.clinelympics.Event" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

  <%
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Key settingsKey = KeyFactory.createKey(Settings.keyKind, Settings.keyName);
		Query query = new Query(Settings.entityKind, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		
		Key eventKey = KeyFactory.createKey(Event.keyKind, Event.keyName);
		query = new Query(Event.entityKind, eventKey).addSort(Event.eventIDName, Query.SortDirection.ASCENDING);
		Filter activeEvents = new FilterPredicate(Event.archivedName, FilterOperator.EQUAL, false);
		query.setFilter(activeEvents);
		List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		%>
<!DOCTYPE html>
<html lang="en">
  <head>
  <% if (settings.isEmpty()) { %>
    	<title>Admin</title>
  <% } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.siteNameName)); %>
      <title>Admin - ${fn:escapeXml(site_name)}</title>
  <% } %>
    <c:import url="/components/head.html" />
  </head>

<body>
  <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <% if (settings.isEmpty()) { %>
          <a class="brand" href="/">Clinelympics</a>
      <% } else { %>
          <a class="brand" href="/">${fn:escapeXml(site_name)}</a>
          <% 
					if (!events.isEmpty()) { %>
            <ul class="nav">
              <li class="divider-vertical"></li>
              <%
							if (events.size() == 1) {
								%>
              	<li ><a href="/summary.jsp">Summary</a></li>
                <%
							} else {
								%>
                <li class="dropdown">
                  <a href="/summary.jsp" class="dropdown-toggle" data-toggle="dropdown">
                    Summary
                    <b class="caret"></b>
                  </a>
                  <ul class="dropdown-menu">
                  <%
									for (Entity ce : events) {
										pageContext.setAttribute("event_id", ce.getProperty(Event.eventIDName));
										pageContext.setAttribute("event_name", ce.getProperty(Event.eventNameName));
										%>
                    <li><a href="/summary.jsp?e=${fn:escapeXml(event_id)}">${fn:escapeXml(event_name)}</a></li>
                    <%
									}
									%>
                  </ul>
                </li>
                <%
							}
							%>
              <li><a href="/scores.jsp">Scores</a></li>
              <li><a href="/medals.jsp">Medals</a></li>
              <li class="divider-vertical"></li>
            </ul>
      			<% 
					} 
				}
			%>
      <div class="pull-right">
      	<ul class="nav">
         <li class="dropdown pull-right">
            <a href="#" class="dropdown-toggle active" data-toggle="dropdown">
              <b class="caret"></b>
            </a>
            <ul class="dropdown-menu pull-right">
              <li class="active"><a href="/admin.jsp">Admin</a></li>
            </ul>
         </li>
        </ul>
      </div>
    </div>
  </div>
	<div class="container">
  <%
		if (settings.isEmpty()) {
		%>
			<div class="row"><p class="text-error">Please <a href="/install.jsp">install</a> Scorebot 9000.</p></div>
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
					if (s.getCurEventID() != -1) {
						pageContext.setAttribute("cur_event", s.getCurEventID());
					} else {
						pageContext.setAttribute("cur_event", "N/A");
					}
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
              <div class="tab-pane active" id="dashboard"><c:import url="/admin/dashboard.jsp" /></div>
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