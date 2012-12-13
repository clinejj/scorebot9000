package com.csoft.clinelympics;

import java.io.IOException;
import java.util.List;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.FetchOptions;
import com.google.appengine.api.datastore.Query;
import com.google.appengine.api.datastore.Query.Filter;
import com.google.appengine.api.datastore.Query.FilterOperator;
import com.google.appengine.api.datastore.Query.FilterPredicate;

@SuppressWarnings("serial")
public class EventServlet extends HttpServlet {
	
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {	
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
	    
	    Query query = new Query(Settings.entityKind, new Settings().getSettingsKey());
	    List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	    
	    if (settings.size() > 0) {
	    	if (settings.size() > 1) System.out.println("Multiple settings entries");
	    	int curID = 0;
			query = new Query(Event.entityKind, new Event().getEventKey());
			Filter isEvent = new FilterPredicate(Event.eventNameName, FilterOperator.EQUAL, req.getParameter(Event.eventNameName).trim());
			query.setFilter(isEvent);
		    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		    
		    if (events.size() == 0) {
				int newID = 1;
		    	query = new Query(Event.entityKind, new Event().getEventKey()).addSort(Event.eventIDName, Query.SortDirection.DESCENDING);
			    events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
			    if (events.size() > 0) {
			    	newID = ((Long) events.get(0).getProperty(Event.eventIDName)).intValue() + 1;
			    }
			    
			    curID = newID;
			    
				Event e = new Event(newID, 
						req.getParameter(Event.eventNameName).trim(), 
						req.getParameter(Event.medalsName).trim());
		
				datastore.put(e.createEntity());
		    } else {
		    	if (events.size() > 1) System.out.println("Multiple events with name " + req.getParameter(Event.eventNameName));
		    	events.get(0).setProperty(Event.medalsName, req.getParameter(Event.medalsName).trim());
		    	curID = ((Long) events.get(0).getProperty(Event.eventIDName)).intValue();
		    	datastore.put(events.get(0));
		    }
		    settings.get(0).setProperty(Settings.curEventName, curID);
		    datastore.put(settings.get(0));
	    }
	    
		resp.sendRedirect("/events.jsp");
	}
}
