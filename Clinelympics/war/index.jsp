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
    	<title>Scorebot 9000</title>
  <% } else {
			pageContext.setAttribute("site_name", settings.get(0).getProperty(Settings.siteNameName)); %>
      <title>${fn:escapeXml(site_name)}</title>
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
 
    <div id="myCarousel" class="carousel slide">
      <div class="carousel-inner">
        <div class="item active">
          <img src="/img/flag-big.jpg" alt="" class="bgimg">
          <div class="container">
                <div class="hero-unit" style="margin-top: 40px;">
                  <div class="row">
                    <img src="/img/emblem.png" height="200px" width="200px" class="pull-left" style="margin-right: 15px;">
                    <h1>2013<br>Clinelympic<br>Games</h1>
                    </div>
                    <p>The annual contest of athletic skill and mental fortitude in celebration of <a href="http://johncline.me/">John Cline</a>. Started in 2012 in honor of John's 25th year of life, the Clinelympic games has become the defining event of our time. This year's games will be held on January 12th, 2013.</p>
                  </div>
                  
                  </div>
                  </div>
          </div>
        </div>

      </div>
    </div>
    <!--
	<div class="container">
  
    <div class="hero-unit">
    <div class="row">
    	<img src="/img/emblem.png" height="200px" width="200px" class="pull-left" style="margin-right: 15px;">
      <h1>2013<br>Clinelympic<br>Games</h1>
      </div>
      <p>The annual contest of athletic skill and mental fortitude in celebration of <a href="http://johncline.me/">John Cline</a>. Started in 2012 in honor of John's 25th year of life, the Clinelympic games has become the defining event of our time. This year's games will be held on January 12th, 2013.</p>
    </div>
    
    </div>
    -->
  	<div class="container">
      <div class="row">
        <div class="span4">
          <h2>Details</h2>
          <p>Opening Ceremonies will begin at 1:00pm on Saturday, January 12th, 2012 at FastKart racing in Ogden. Events will take place at FastKart racing and Boondocks.</p>
          <p>Closing Ceremonies will begin at 7:00pm at Squatter’s Pub Brewery in Salt Lake City</p>
          <p><a class="btn" href="http://goo.gl/maps/u1jri" target="_blank">View Map &raquo;</a></p>
          <br>
          <h2>RSVP</h2>
          <p>Please RSVP no later than Friday, January 11th to John Cline for both entry into the games and dinner.</p>
          <p><a class="btn" href="http://www.facebook.com/events/393282987419472/" target="_blank">RSVP &raquo;</a></p>
        </div>
        <div class="span4">
          <h2>Events</h2>
          <ul>
            <li>FastKart racing (5 minute qualifier, 20 lap race)</li>
            <li>Bowling</li>
            <li>Skeeball</li>
            <li>Deal or No Deal</li>
            <li>Fire and Ice</li>
            <li>“Throw the balls at the screen”</li>
            <li>Laser Tag</li>
          </ul>
          <h2>Rules</h2>
          <ul>
            <li>All events are team based</li>
              <ul>
              <li>Team size is 2 (or 3 if there is a total odd number of people)</li>
              <li>Team uniforms are not required, but highly encouraged</li>
              </ul>
            <li>All events will be best of 2 games, with the exceptions below</li>
              <ul>
              <li>FastKart racing and laser tag may be best of 2, time permitting</li>
              <li>“Deal or No Deal” and “throw the balls at the screen” will both be performed as team events</li>
              </ul>
            <li>Scoring will be an average of each team member’s score for the event</li>
              <ul><li>Teams will be paired off to ensure accurate scorekeeping</li></ul>
            <li>Overall scoring will be pure medal count</li>
              <ul><li>There will be prizes for overall gold, silver, and bronze</li></ul>
          </ul>
       </div>
        <div class="span4">
          <h2>2012 Results</h2>
          <p>Check out the results from last year's match.</p>
          <p><a class="btn" href="/standings.jsp?e=1">View &raquo;</a></p>
        </div>
    </div>
  <c:import url="/components/footer.html" />
  </div>
  </body>
</html>