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
public class AddServlet extends HttpServlet {
	public static final String TYPE_NAME = "type";
	
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {		
		boolean isSuccess = false;
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		
		Query query = new Query(Settings.entityKind, new Settings().getSettingsKey());
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		if (!settings.isEmpty()) {
			if (settings.size() > 1) System.out.println("Settings has mulitple entries.");
			int curEvent = ((Long) settings.get(0).getProperty(Settings.curEventName)).intValue();
			String type = req.getParameter(TYPE_NAME);
			
			if (type.equals(Player.entityKind)) {
				// Add a player
				Player player = new Player(req.getParameter(Player.playerIDName), 
						req.getParameter(Player.playerNameName).trim(), 
						req.getParameter(Player.teamNameName).trim(),
						curEvent);
				datastore.put(player.createEntity());
				isSuccess = true;
			} else if (type.equals(Score.entityKind)) {
				// Add a score
				Score score = new Score(req.getParameter(Score.playerIDName), 
						Integer.parseInt(req.getParameter(Score.gameIDName).trim()), 
						Integer.parseInt(req.getParameter(Score.playerScoreName).trim()),
						curEvent);
				datastore.put(score.createEntity());
				isSuccess = true;
			} else if (type.equals(Game.entityKind)) {
				// Add a game
				query = new Query(Game.entityKind, new Game().getGameKey());
				Filter isGame = new FilterPredicate(Game.gameNameName, FilterOperator.EQUAL, req.getParameter(Game.gameNameName).trim());
				query.setFilter(isGame);
			    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
			    
			    if (games.size() == 0) {
					int newID = 1;
			    	query = new Query(Game.entityKind, new Game().getGameKey()).addSort(Game.gameIDName, Query.SortDirection.DESCENDING);
				    games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				    if (games.size() > 0) {
				    	newID = ((Long) games.get(0).getProperty(Game.gameIDName)).intValue() + 1;
				    }
					Game game = new Game(newID, 
							req.getParameter(Game.gameNameName).trim(), 
							Boolean.parseBoolean(req.getParameter(Game.scoreTypeName).trim()),
							curEvent);
			
					datastore.put(game.createEntity());
			    } else {
			    	if (games.size() > 1) System.out.println("Multiple games with name " + req.getParameter(Game.gameNameName));
			    	games.get(0).setProperty(Game.scoreTypeName, Boolean.parseBoolean(req.getParameter(Game.scoreTypeName).trim()));
			    	datastore.put(games.get(0));
			    }
			    isSuccess = true;
			} else if (type.equals(Name.entityKind)) {
				// Add a name
				Name n = new Name(req.getParameter(Name.nameStr).trim());

				datastore.put(n.createEntity());
				isSuccess = true;
			} else if (type.equals(Event.entityKind)) {
				// Add an event
				int curID = 0;
				query = new Query(Event.entityKind, new Event().getEventKey());
				Filter isEvent = new FilterPredicate(Event.eventNameName, FilterOperator.EQUAL, req.getParameter(Event.eventNameName).trim());
				query.setFilter(isEvent);
			    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
			    
			    if (events.isEmpty()) {
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
			    isSuccess = true;
			    curEvent = curID;
			}
		}
		
		resp.getOutputStream().println(isSuccess);
	}
}
