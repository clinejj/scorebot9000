<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
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
    	<title>Details</title>
  <% } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.SITE_NAME)); %>
      <title>Details - ${fn:escapeXml(site_name)}</title>
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
							%>
              <li><a href="/medals.jsp">Medals</a></li>
								<li><a href="/scores.jsp">Scores</a></li>				
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
    <div class="row">
        <h2>Details</h2>
		  <p>Opening Ceremonies will begin at 1:00pm on Sunday, January 14th, 2018 at Gutter Bar in Williamsburg. Events will take place at Gutter Bar and Barcade in Williamsburg.</p>
		  <p>Closing Ceremonies will begin at 7:00pm, at The Saint Austere in Williamsburg. After-party location will be TBD.</p>
		  <p><a class="btn" href="https://mapsengine.google.com/map/edit?mid=zafwTX89QNtI.kcj-egdPfzfM" target="_blank">View Map &raquo;</a></p>
        <br>
        <h2>RSVP</h2>
        <p>Please RSVP no later than Friday, January 12th to John Cline for both entry into the games and dinner.</p>
        <p><a class="btn" href="https://www.facebook.com/events/369907473476776/" target="_blank">RSVP &raquo;</a></p>
				<br>
        <h2>Events</h2>
        <ol>
            <li>Bowling</li>
            <li>Arkanoid</li>
            <li>Metal Slug X*</li>
            <li>Ms. Pacman</li>
            <li>Rampage*</li>
            <li>Teenage Mutant Ninja Turtles*</li>
            <li>Tetris</li>
        </ol>
        <p>* team event</p>
        <h2>How To</h2>
        <p>Text the following commands to 909-SCORE-11 (909-726-7311)</p>
        <ul>
            <li>REGISTER &lt;team name&gt;</li>
            <li>SCORE &lt;game id (number from above)&gt; &lt;score&gt;</li>
            <li>WHO</li>
            <li>CHANGE TEAM &lt;new team name&gt;</li>
            <li>CHANGE NAME &lt;new name&gt;</li>
            <li>HELP</li>
        </ul>
        <h2>Rules</h2>
        <ul>
          <li>All events are team based</li>
            <ul>
            <li>Team size is 2 (or 3 if there is a total odd number of people)</li>
            <li>Team uniforms are not required, but highly encouraged</li>
            </ul>
          <li>All events will be best of 2 games, with the exceptions below</li>
            <li>Scoring will be an average of each team member's score for the event*</li>
              <ul>
              	<li>Teams will be paired off to ensure accurate scorekeeping</li>
              	<li>*Metal Slug X, Rampage, and TMNT will be performed as team events (players play at same time, score is total for all players)</li>
              </ul>
          <li>Overall scoring will be pure medal count</li>
            <ul><li>There will be prizes for overall gold, silver, and bronze</li></ul>
        </ul>
    </div>

    <div class="row" id="map">
    	<h2>Map</h2>
    	<iframe src="https://mapsengine.google.com/map/embed?mid=zafwTX89QNtI.kcj-egdPfzfM" width="640" height="480"></iframe>
    </div>

  <c:import url="/components/footer.html" />
  </div>
  </body>
</html>