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
<%@ page import="com.csoft.scorebot.Settings" %>
<%@ page import="com.csoft.scorebot.Event" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

  <%
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Key settingsKey = KeyFactory.createKey(Settings.KEY_KIND, Settings.KEY_NAME);
		Query query = new Query(Settings.ENTITY_KIND, settingsKey);
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		
		Key eventKey = KeyFactory.createKey(Event.KEY_KIND, Event.KEY_NAME);
		query = new Query(Event.ENTITY_KIND, eventKey).addSort(Event.EVENT_ID, Query.SortDirection.ASCENDING);
		Filter unArchivedEvents = new FilterPredicate(Event.ARCHIVED_NAME, FilterOperator.EQUAL, false);
		query.setFilter(unArchivedEvents);
		List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		%>
<!DOCTYPE html>
<html lang="en">
  <head>
  <% if (settings.isEmpty()) { %>
    	<title>Admin</title>
  <% } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.SITE_NAME)); %>
      <title>Admin - ${fn:escapeXml(site_name)}</title>
  <% } %>
    <c:import url="/components/head.html" />
  </head>

<body>
  <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <% if (settings.isEmpty()) { %>
          <a class="brand" href="/" id="site_name">Scorebot 9000</a>
      <% } else { %>
          <a class="brand" href="/" id="site_name">${fn:escapeXml(site_name)}</a>
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
                	<%
                  if (((Long) settings.get(0).getProperty(Settings.CUR_EVENT)).intValue() != -1) {
										%>
                    <a href="/summary.jsp" class="dropdown-toggle" data-toggle="dropdown">
                      Summary
                      <b class="caret"></b>
                    </a>
                    <%
									} else {
										pageContext.setAttribute("event_id", events.get(0).getProperty(Event.EVENT_ID));
										%>
                    <a href="/summary.jsp?e=${fn:escapeXml(event_id)}" class="dropdown-toggle" data-toggle="dropdown">
                      Summary
                      <b class="caret"></b>
                    </a>
                    <%
									}
									%>
                  <ul class="dropdown-menu">
                  <%
									for (Entity ce : events) {
										pageContext.setAttribute("event_id", ce.getProperty(Event.EVENT_ID));
										pageContext.setAttribute("event_name", ce.getProperty(Event.EVENT_NAME));
										%>
                    <li><a href="/summary.jsp?e=${fn:escapeXml(event_id)}">${fn:escapeXml(event_name)}</a></li>
                    <%
									}
									%>
                  </ul>
                </li>
                <%
							}
							if (((Long) settings.get(0).getProperty(Settings.CUR_EVENT)).intValue() != -1) {
								%>
								<li><a href="/medals.jsp">Medals</a></li>
								<li><a href="/scores.jsp">Scores</a></li>				
                <%
							}
							%>
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
        <div class="row" id="setting_response"></div>
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
         	Your admin number is: <span id="admin_num">${fn:escapeXml(admin_num)}</span>
          </div>
          <div class="row">
          The current event is: <span id="current_event">${fn:escapeXml(cur_event)}</span>
          </div>
          <div class="row">
          <a href="#updateModal" role="button" class="btn" data-toggle="modal">Update</a>
          </div>
          <div class="row">
          	<p> </p>
          	<div id="updateModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
              <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                <h3 id="myModalLabel">Update Admin Settings</h3>
              </div>
              <div class="modal-body">
              	<%
								pageContext.setAttribute("eventval", Settings.CUR_EVENT);
								pageContext.setAttribute("nameval", Settings.SITE_NAME);
								pageContext.setAttribute("numval", Settings.ADMIN_NUM);
								%>
              	<form id="settings_form" class="form-horizontal">
                <div class="control-group">
                  <label class="control-label" for="${fn:escapeXml(numval)}">Phone number?</label>
                  <div class="controls">
                    <input type="text" id="${fn:escapeXml(numval)}" name="${fn:escapeXml(numval)}" placeholder="${fn:escapeXml(admin_num)}" maxlength="10" size="10">
                  </div>
                </div>
                <div class="control-group">
                  <label class="control-label" for="${fn:escapeXml(nameval)}">Site Name</label>
                  <div class="controls">
                    <input type="text" id="${fn:escapeXml(nameval)}" name="${fn:escapeXml(nameval)}" placeholder="${fn:escapeXml(site_name)}" maxlength="35" size="35">
                  </div>
                </div>
                <div class="control-group">
                	<label class="control-label" for="${fn:escapeXml(eventval)}">Current Event</label>
                  <div class="controls">
                    <select name="${fn:escapeXml(eventval)}" id="${fn:escapeXml(eventval)}">
                    	<option value="-1">No event</option>
                    	<%
											query = new Query(Event.ENTITY_KIND, eventKey).addSort(Event.EVENT_ID, Query.SortDirection.ASCENDING);
											events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
											for (Entity ce : events) {
												pageContext.setAttribute("event_id", ce.getProperty(Event.EVENT_ID));
												pageContext.setAttribute("event_name", ce.getProperty(Event.EVENT_NAME));
												if (((Long) ce.getProperty(Event.EVENT_ID)).intValue() == s.getCurEventID()) {
													%>
													<option value="${fn:escapeXml(event_id)}" selected>${fn:escapeXml(event_id)} - ${fn:escapeXml(event_name)}</option>
													<%											
												} else {
													%>
													<option value="${fn:escapeXml(event_id)}">${fn:escapeXml(event_id)} - ${fn:escapeXml(event_name)}</option>
													<%
												}
											}
											%>
                    </select>
                  </div>
                </div>
                <input type="hidden" name="type" value="setting"/>
                </form>
              </div>
              <div class="modal-footer">
                <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
                <button class="btn btn-primary" onClick="updateSettings();">Save changes</button>
              </div>
            </div>
          </div>
          <div class="row">
            <ul class="nav nav-tabs">
              <li class="active"><a href="#dashboard" data-toggle="tab">Dashboard</a></li>
              <li onClick="unBindTable();"><a href="#event" data-toggle="tab">Events</a></li>
              <li onClick="unBindTable();"><a href="#game" data-toggle="tab">Games</a></li>
              <li onClick="unBindTable();"><a href="#player" data-toggle="tab">Players</a></li>
              <li onClick="unBindTable();"><a href="#score" data-toggle="tab">Scores</a></li>
              <li onClick="unBindTable();"><a href="#name" data-toggle="tab">Names</a></li>
              <li onClick="unBindTable();"><a href="#text" data-toggle="tab">Texts</a></li>
            </ul>
          </div>
          <div class="row">
            <div class="tab-content">
              <div class="tab-pane active" id="dashboard"><c:import url="/admin/dashboard.jsp" /></div>
              <div class="tab-pane" id="event"><c:import url="/admin/events.jsp" /></div>
              <div class="tab-pane" id="game"><c:import url="/admin/games.jsp" /></div>
              <div class="tab-pane" id="player"><c:import url="/admin/players.jsp" /></div>
              <div class="tab-pane" id="score"><c:import url="/admin/scores.jsp" /></div>
              <div class="tab-pane" id="name"><c:import url="/admin/names.jsp" /></div>
              <div class="tab-pane" id="text"><c:import url="/admin/texts.jsp" /></div>
            </div>
          </div>
          <c:import url="/components/footer.html" />
          <script type="application/javascript" src="js/clinelympics.js"></script>
				<%
        } else {
        %>
        	<div class="row">
          <div class="alert alert-error">You do not have permission to view this page. <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">Logout</a></div>
          </div>
          <%
      	}
			} else {
			%>
      <div class="row">
				<h2>Admin Panel</h2>      
      </div>
      <div class="row">
      <div class="alert alert-info">Please <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">sign in</a>.</div>
      </div>
			<%
			}
		}
		%>
  </body>
</html>