package com.csoft.clinelympics;

import java.io.IOException;
import java.util.Date;
import java.util.List;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.FetchOptions;
import com.google.appengine.api.datastore.Query;
import com.google.appengine.api.datastore.Query.CompositeFilterOperator;
import com.google.appengine.api.datastore.Query.Filter;
import com.google.appengine.api.datastore.Query.FilterOperator;
import com.google.appengine.api.datastore.Query.FilterPredicate;

@SuppressWarnings("serial")
public class AddServlet extends HttpServlet {
	public static final String TYPE_NAME = "type";
	public static final String USER_HEADER = "userEmail";
	
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {		
		String strResp = "";
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		
		Query query = new Query(Settings.entityKind, new Settings().getSettingsKey());
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		if (!settings.isEmpty()) {
			if (settings.size() > 1) System.out.println("Settings has multiple entries.");
			int curEvent = ((Long) settings.get(0).getProperty(Settings.curEventName)).intValue();
			int storeEvent = curEvent;
			if (req.getParameter(Event.eventIDName) != null) {
				storeEvent = Integer.parseInt(req.getParameter(Event.eventIDName));
			}
			String type = req.getParameter(TYPE_NAME);
			if (((String) settings.get(0).getProperty(Settings.adminName)).equals(req.getHeader(USER_HEADER))) {
				if (type.equals(Player.entityKind)) {
					// Add a player
					query = new Query(Event.entityKind, new Event().getEventKey());
					Filter feID = new FilterPredicate(Player.eventIDName, FilterOperator.EQUAL, storeEvent);
					query.setFilter(feID);
					List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					if (events.size() > 0) {
						if (events.size() > 1) System.out.println("Multiple events with ID " + Integer.toString(storeEvent));
						query = new Query(Player.entityKind, new Player().getPlayerKey());
						Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, req.getParameter(Player.playerIDName).trim());
						feID = new FilterPredicate(Player.eventIDName, FilterOperator.EQUAL, storeEvent);
						query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
					    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (players.isEmpty()) {
							Player player = new Player(req.getParameter(Player.playerIDName), 
									req.getParameter(Player.playerNameName).trim(), 
									req.getParameter(Player.teamNameName).trim(),
									storeEvent);
							datastore.put(player.createEntity());
							strResp = "New player created.";
					    } else {
					    	if (players.size() > 1) System.out.println("Multiple players with ID " + req.getParameter(Player.playerIDName));
					    	players.get(0).setProperty(Player.playerNameName, req.getParameter(Player.playerNameName));
					    	players.get(0).setProperty(Player.teamNameName, req.getParameter(Player.teamNameName));
				    		players.get(0).setProperty(Player.eventIDName, storeEvent);
					    	datastore.put(players.get(0));
					    	strResp = "Player updated.";
					    }
					} else {
						strResp = "err: Event with ID " + Integer.toString(storeEvent) + " not found.";
					}
				} else if (type.equals(Score.entityKind)) {
					// Add a score		
					query = new Query(Player.entityKind, new Player().getPlayerKey());
					Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, req.getParameter(Player.playerIDName));
					Filter feID = new FilterPredicate(Score.eventIDName, FilterOperator.EQUAL, storeEvent);
					query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
				    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				    if (players.size() > 0) {
				    	if (players.size() > 1) System.out.println("Multiple players for player with ID " + req.getParameter(Player.playerIDName));
				    	query = new Query(Game.entityKind, new Game().getGameKey());
						Filter isGame = new FilterPredicate(Game.gameIDName, FilterOperator.EQUAL, Integer.parseInt(req.getParameter(Game.gameIDName)));
						query.setFilter(isGame);
					    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (games.size() > 0) {
					    	if (games.size() > 1) System.out.println("Multiple games found for game " + req.getParameter(Game.gameIDName));
							query = new Query(Score.entityKind, new Score().getScoreKey());
							query.addSort(Score.dateName, Query.SortDirection.DESCENDING);
							Filter fpID = new FilterPredicate(Score.playerIDName, FilterOperator.EQUAL, req.getParameter(Player.playerIDName));
							Filter fgID = new FilterPredicate(Score.gameIDName, FilterOperator.EQUAL, Integer.parseInt(req.getParameter(Game.gameIDName)));
							query.setFilter(CompositeFilterOperator.and(fpID,fgID,feID));
							List<Entity> scores = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
							if (scores.size() == 0) {
								Score score = new Score(req.getParameter(Score.playerIDName), 
										Integer.parseInt(req.getParameter(Score.gameIDName).trim()), 
										Integer.parseInt(req.getParameter(Score.playerScoreName).trim()),
										storeEvent);
								datastore.put(score.createEntity());
								strResp = "Score added.";
							} else {
								scores.get(0).setProperty(Score.playerScoreName, Integer.parseInt(req.getParameter(Score.playerScoreName).trim()));
								scores.get(0).setProperty(Score.dateName, new Date());
								scores.get(0).setProperty(Score.eventIDName, storeEvent);
								datastore.put(scores.get(0));
								if (scores.size() > 1) {
									System.out.println("Multiple scores for player " + req.getParameter(Player.playerIDName) + " and game " + req.getParameter(Game.gameIDName));
								}
								strResp = "Score updated.";
							}
					    } else {
					    	strResp = "err: Couldn't find that game ID. " + req.getParameter(Game.gameIDName);
					    }
				    } else {
				    	strResp = "err: Couldn't find playerID " + req.getParameter(Player.playerIDName);
				    }
				} else if (type.equals(Game.entityKind)) {
					// Add a game
					query = new Query(Event.entityKind, new Event().getEventKey());
					Filter feID = new FilterPredicate(Player.eventIDName, FilterOperator.EQUAL, storeEvent);
					query.setFilter(feID);
					List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					if (events.size() > 0) {
						if (events.size() > 1) System.out.println("Multiple events with ID " + Integer.toString(storeEvent));
						query = new Query(Game.entityKind, new Game().getGameKey());
						Filter isGame = new FilterPredicate(Game.gameNameName, FilterOperator.EQUAL, req.getParameter(Game.gameNameName).trim());
						query.setFilter(CompositeFilterOperator.and(isGame,feID));
					    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    
					    if (games.size() == 0) {
							int newID = 1;
					    	query = new Query(Game.entityKind, new Game().getGameKey()).addSort(Game.gameIDName, Query.SortDirection.DESCENDING);
					    	query.setFilter(feID);
					    	games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
						    if (games.size() > 0) {
						    	newID = ((Long) games.get(0).getProperty(Game.gameIDName)).intValue() + 1;
						    }
							Game game = new Game(newID, 
									req.getParameter(Game.gameNameName).trim(), 
									Boolean.parseBoolean(req.getParameter(Game.scoreTypeName).trim()),
									storeEvent);
					
							datastore.put(game.createEntity());
							strResp = "New game created.";
					    } else {
					    	if (games.size() > 1) System.out.println("Multiple games with name " + req.getParameter(Game.gameNameName));
					    	games.get(0).setProperty(Game.scoreTypeName, Boolean.parseBoolean(req.getParameter(Game.scoreTypeName).trim()));
					    	datastore.put(games.get(0));
					    	strResp = "Game updated.";
					    }
					} else {
						strResp = "err: Event with ID " + Integer.toString(storeEvent) + " not found.";
					}
				} else if (type.equals(Name.entityKind)) {
					// Add a name
					query = new Query(Name.entityKind, new Name().getNameKey());
					Filter isName = new FilterPredicate(Name.nameStr, FilterOperator.EQUAL, req.getParameter(Name.nameStr).trim());
					query.setFilter(isName);
				    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				    if (names.isEmpty()) {
						Name n = new Name(req.getParameter(Name.nameStr).trim());
						datastore.put(n.createEntity());
						strResp = "Name added";
				    } else {
				    	strResp = "err: Name already exists.";
				    }
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
						strResp = "New event added.";
				    } else {
				    	if (events.size() > 1) System.out.println("Multiple events with name " + req.getParameter(Event.eventNameName));
				    	events.get(0).setProperty(Event.medalsName, req.getParameter(Event.medalsName).trim());
				    	curID = ((Long) events.get(0).getProperty(Event.eventIDName)).intValue();
				    	datastore.put(events.get(0));
				    	strResp = "Event updated.";
				    }
				    settings.get(0).setProperty(Settings.curEventName, curID);
				    datastore.put(settings.get(0));
				    curEvent = curID;
				}
			}
		}
		
		resp.getOutputStream().println(strResp);
	}
}
