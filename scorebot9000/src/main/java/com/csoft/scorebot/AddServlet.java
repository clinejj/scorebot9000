package com.csoft.scorebot;

import java.io.IOException;
import java.util.ArrayList;
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
import com.google.appengine.api.datastore.Query.SortDirection;

@SuppressWarnings("serial")
public class AddServlet extends HttpServlet {
	public static final String TYPE_NAME = "type";
	public static final String USER_HEADER = "userEmail";
	public static final String METHOD_ADD = "add";
	public static final String METHOD_DEL = "delete";
	public static final String METHOD = "method";
	public static final String ERR_STR = "err: ";
	
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {		
		String strResp = "";
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		
		Query query = new Query(Settings.ENTITY_KIND, new Settings().getSettingsKey());
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		if (!settings.isEmpty()) {
			if (settings.size() > 1) System.out.println("Settings has multiple entries.");
			int curEvent = ((Long) settings.get(0).getProperty(Settings.CUR_EVENT)).intValue();
			int storeEvent = curEvent;
			if (req.getParameter(Event.EVENT_ID) != null) {
				storeEvent = Integer.parseInt(req.getParameter(Event.EVENT_ID));
			}
			String type = req.getParameter(TYPE_NAME);
			if (((String) settings.get(0).getProperty(Settings.ADMIN_NAME)).equals(req.getHeader(USER_HEADER))) {
				if (type.equals(Player.ENTITY_KIND)) {
					// Add a player
					query = new Query(Event.ENTITY_KIND, new Event().getEventKey());
					Filter feID = new FilterPredicate(Player.EVENT_ID, FilterOperator.EQUAL, storeEvent);
					query.setFilter(feID);
					List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					if (events.size() > 0) {
						if (events.size() > 1) System.out.println("Multiple events with ID " + Integer.toString(storeEvent));
						query = new Query(Player.ENTITY_KIND, new Player().getPlayerKey());
						Filter isPlayer = new FilterPredicate(Player.PLAYER_ID, FilterOperator.EQUAL, req.getParameter(Player.PLAYER_ID).trim());
						feID = new FilterPredicate(Player.EVENT_ID, FilterOperator.EQUAL, storeEvent);
						query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
					    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (players.isEmpty()) {
					    	if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
								Player player = new Player(req.getParameter(Player.PLAYER_ID), 
										req.getParameter(Player.PLAYER_NAME).trim(), 
										req.getParameter(Player.TEAM_NAME).trim(),
										storeEvent);
								datastore.put(player.createEntity());
								strResp = "New player '" + req.getParameter(Player.PLAYER_NAME) + "' created.";
					    	} else {
					    		strResp = ERR_STR + " Player with ID " + req.getParameter(Player.PLAYER_ID) + " not found.";
					    	}
					    } else {
					    	if (players.size() > 1) System.out.println("Multiple players with ID " + req.getParameter(Player.PLAYER_ID));
					    	if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
						    	players.get(0).setProperty(Player.PLAYER_NAME, req.getParameter(Player.PLAYER_NAME));
						    	players.get(0).setProperty(Player.TEAM_NAME, req.getParameter(Player.TEAM_NAME));
					    		players.get(0).setProperty(Player.EVENT_ID, storeEvent);
						    	datastore.put(players.get(0));
						    	strResp = "Player '" + req.getParameter(Player.PLAYER_NAME) + "' updated.";
					    	} else {
					    		strResp = "Player '" + ((String) players.get(0).getProperty(Player.PLAYER_NAME)) + "' deleted.";
					    		datastore.delete(players.get(0).getKey());
					    	}
					    }
					} else {
						strResp = ERR_STR + " Event with ID " + Integer.toString(storeEvent) + " not found.";
					}
				} else if (type.equals(Score.ENTITY_KIND)) {
					// Add a score		
					query = new Query(Player.ENTITY_KIND, new Player().getPlayerKey());
					Filter isPlayer = new FilterPredicate(Player.PLAYER_ID, FilterOperator.EQUAL, req.getParameter(Player.PLAYER_ID));
					Filter feID = new FilterPredicate(Score.EVENT_ID, FilterOperator.EQUAL, storeEvent);
					query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
				    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				    if (players.size() > 0) {
				    	if (players.size() > 1) System.out.println("Multiple players for player with ID " + req.getParameter(Player.PLAYER_ID));
				    	query = new Query(Game.ENTITY_KIND, new Game().getGameKey());
						Filter isGame = new FilterPredicate(Game.GAME_ID, FilterOperator.EQUAL, Integer.parseInt(req.getParameter(Game.GAME_ID)));
						query.setFilter(isGame);
					    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (games.size() > 0) {
					    	if (games.size() > 1) System.out.println("Multiple games found for game " + req.getParameter(Game.GAME_ID));
							query = new Query(Score.ENTITY_KIND, new Score().getScoreKey());
							query.addSort(Score.DATE, Query.SortDirection.DESCENDING);
							Filter fpID = new FilterPredicate(Score.PLAYER_ID, FilterOperator.EQUAL, req.getParameter(Player.PLAYER_ID));
							Filter fgID = new FilterPredicate(Score.GAME_ID, FilterOperator.EQUAL, Integer.parseInt(req.getParameter(Game.GAME_ID)));
							query.setFilter(CompositeFilterOperator.and(fpID,fgID,feID));
							List<Entity> scores = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
							if (scores.size() == 0) {
								if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
									Score score = new Score(req.getParameter(Score.PLAYER_ID), 
											Integer.parseInt(req.getParameter(Score.GAME_ID).trim()), 
											Integer.parseInt(req.getParameter(Score.PLAYER_SCORE).trim()),
											storeEvent);
									datastore.put(score.createEntity());
									strResp = "Score for player " + req.getParameter(Player.PLAYER_ID) + " added.";
								} else {
									strResp = ERR_STR + " Score not found for player " + req.getParameter(Player.PLAYER_ID) + " and game " + req.getParameter(Game.GAME_ID);
								}
							} else {
								if (scores.size() > 1) {
									System.out.println("Multiple scores for player " + req.getParameter(Player.PLAYER_ID) + " and game " + req.getParameter(Game.GAME_ID));
								}
								if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
									scores.get(0).setProperty(Score.PLAYER_SCORE, Integer.parseInt(req.getParameter(Score.PLAYER_SCORE).trim()));
									scores.get(0).setProperty(Score.DATE, new Date());
									scores.get(0).setProperty(Score.EVENT_ID, storeEvent);
									datastore.put(scores.get(0));
									
									strResp = "Score for player " + req.getParameter(Player.PLAYER_ID) + " updated.";
								} else {
									datastore.delete(scores.get(0).getKey());
									strResp = "Score for player " + req.getParameter(Player.PLAYER_ID) + " deleted.";
								}
							}
					    } else {
					    	strResp = ERR_STR + " Couldn't find that game ID " + req.getParameter(Game.GAME_ID);
					    }
				    } else {
				    	strResp = ERR_STR + " Couldn't find playerID " + req.getParameter(Player.PLAYER_ID);
				    }
				} else if (type.equals(Game.ENTITY_KIND)) {
					// Add a game
					query = new Query(Event.ENTITY_KIND, new Event().getEventKey());
					Filter feID = new FilterPredicate(Player.EVENT_ID, FilterOperator.EQUAL, storeEvent);
					query.setFilter(feID);
					List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					if (events.size() > 0) {
						if (events.size() > 1) System.out.println("Multiple events with ID " + Integer.toString(storeEvent));
						query = new Query(Game.ENTITY_KIND, new Game().getGameKey());
						Filter isGame = new FilterPredicate(Game.GAME_NAME, FilterOperator.EQUAL, req.getParameter(Game.GAME_NAME).trim());
						query.setFilter(CompositeFilterOperator.and(isGame,feID));
					    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    
					    if (games.size() == 0) {
					    	if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
								int newID = 1;
						    	query = new Query(Game.ENTITY_KIND, new Game().getGameKey()).addSort(Game.GAME_ID, Query.SortDirection.DESCENDING);
						    	query.setFilter(feID);
						    	games = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(2));
							    if (games.size() > 0) {
							    	newID = ((Long) games.get(0).getProperty(Game.GAME_ID)).intValue() + 1;
							    }
								Game game = new Game(newID, 
										req.getParameter(Game.GAME_NAME).trim(), 
										Boolean.parseBoolean(req.getParameter(Game.SCORE_TYPE).trim()),
										storeEvent);
						
								datastore.put(game.createEntity());
								strResp = "New game '" + req.getParameter(Game.GAME_NAME) + "' created.";
					    	} else {
					    		strResp = ERR_STR + " Game '" + req.getParameter(Game.GAME_NAME) + "' was not found.";
					    	}
					    } else {
					    	if (games.size() > 1) System.out.println("Multiple games with name " + req.getParameter(Game.GAME_NAME));
					    	if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
						    	games.get(0).setProperty(Game.SCORE_TYPE, Boolean.parseBoolean(req.getParameter(Game.SCORE_TYPE).trim()));
						    	datastore.put(games.get(0));
						    	strResp = "Game '" + req.getParameter(Game.GAME_NAME) + "' updated.";
					    	} else {
					    		datastore.delete(games.get(0).getKey());
					    		strResp = "Game '" + req.getParameter(Game.GAME_NAME) + "' deleted.";
					    	}
					    }
					} else {
						strResp = ERR_STR + " Event with ID " + Integer.toString(storeEvent) + " not found.";
					}
				} else if (type.equals(Name.ENTITY_KIND)) {
					// Add a name
					query = new Query(Name.ENTITY_KIND, new Name().getNameKey());
					Filter isName = new FilterPredicate(Name.NAME, FilterOperator.EQUAL, req.getParameter(Name.NAME).trim());
					query.setFilter(isName);
				    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				    if (names.isEmpty()) {
				    	if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
							Name n = new Name(req.getParameter(Name.NAME).trim());
							datastore.put(n.createEntity());
							strResp = "Name added";
				    	} else {
				    		strResp = ERR_STR + " Name '" + req.getParameter(Name.NAME) + "' does not exist.";
				    	}
				    } else {
				    	if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
				    		strResp = ERR_STR + " Name '" + req.getParameter(Name.NAME) + "' already exists.";
				    	} else {
				    		if (names.size() > 1) System.out.println("Multiple entries for name: " + req.getParameter(Name.NAME));
				    		datastore.delete(names.get(0).getKey());
				    		strResp = "Name '" + req.getParameter(Name.NAME) + "' deleted.";
				    	}
				    }
				} else if (type.equals(Event.ENTITY_KIND)) {
					// Add an event
					if (((String) req.getParameter(METHOD)).equalsIgnoreCase(METHOD_ADD)) {
						if (req.getParameter(Event.ACTIVE_NAME).equals("true") && req.getParameter(Event.ACTIVE_NAME).equals(req.getParameter(Event.ARCHIVED_NAME))) {
							strResp = ERR_STR + " Cannot set an event both active and archived.";
						} else if (req.getParameter(Event.TEAMSCORE_NAME).equalsIgnoreCase("true") && req.getParameter(Event.TEAM_SUPPORT).equalsIgnoreCase("false")) {
							strResp = ERR_STR + " Cannot have team scoring without team support.";
						} else {
						    if (Boolean.parseBoolean(req.getParameter(Event.ACTIVE_NAME))) {
						    	deactivateEvents();
						    }
						    
							int curID = 0;
							query = new Query(Event.ENTITY_KIND, new Event().getEventKey());
							Filter isEvent = new FilterPredicate(Event.EVENT_NAME, FilterOperator.EQUAL, req.getParameter(Event.EVENT_NAME).trim());
							query.setFilter(isEvent);
						    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
						    
						    if (events.isEmpty()) {
								int newID = 1;
						    	query = new Query(Event.ENTITY_KIND, new Event().getEventKey());
						    	query.addSort(Event.EVENT_ID, SortDirection.DESCENDING);
							    events = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(2));
							    if (events.size() > 0) {
							    	newID = ((Long) events.get(0).getProperty(Event.EVENT_ID)).intValue() + 1;
							    }
							    
							    curID = newID;
							    
								Event e = new Event(newID, 
										req.getParameter(Event.EVENT_NAME).trim(), 
										req.getParameter(Event.MEDALS_NAME).trim(),
										Boolean.parseBoolean(req.getParameter(Event.ARCHIVED_NAME)),
										Boolean.parseBoolean(req.getParameter(Event.ACTIVE_NAME)),
										Boolean.parseBoolean(req.getParameter(Event.TEAMSCORE_NAME)),
										Boolean.parseBoolean(req.getParameter(Event.TEAM_SUPPORT)));
						
								datastore.put(e.createEntity());
								strResp = "New event '" + req.getParameter(Event.EVENT_NAME) + "' added.";
						    } else {
						    	if (events.size() > 1) System.out.println("Multiple events with name " + req.getParameter(Event.EVENT_NAME));
						    	events.get(0).setProperty(Event.MEDALS_NAME, req.getParameter(Event.MEDALS_NAME).trim());
						    	events.get(0).setProperty(Event.ARCHIVED_NAME, Boolean.parseBoolean(req.getParameter(Event.ARCHIVED_NAME)));
						    	events.get(0).setProperty(Event.ACTIVE_NAME, Boolean.parseBoolean(req.getParameter(Event.ACTIVE_NAME)));
						    	events.get(0).setProperty(Event.TEAMSCORE_NAME, Boolean.parseBoolean(req.getParameter(Event.TEAMSCORE_NAME)));
						    	events.get(0).setProperty(Event.TEAM_SUPPORT, Boolean.parseBoolean(req.getParameter(Event.TEAM_SUPPORT)));
						    	curID = ((Long) events.get(0).getProperty(Event.EVENT_ID)).intValue();
						    	datastore.put(events.get(0));
						    	strResp = "Event '" + req.getParameter(Event.EVENT_NAME) + "' updated.";
						    }
						   
						    if (Boolean.parseBoolean(req.getParameter(Event.ACTIVE_NAME))) {
						    	settings.get(0).setProperty(Settings.CUR_EVENT, curID);
							    datastore.put(settings.get(0));
							    resetNames(curID);
							    curEvent = curID;
							    strResp = strResp + "&&" + Integer.toString(curEvent);
						    } else {
						    	if (curID == curEvent) {
						    		settings.get(0).setProperty(Settings.CUR_EVENT, -1);
								    datastore.put(settings.get(0));
								    curEvent = -1;
								    strResp = strResp + "&&" + Integer.toString(curEvent);
								    resetNames(-1);
						    	}
						    }
						}
					} else {
						query = new Query(Event.ENTITY_KIND, new Event().getEventKey());
						Filter isEvent = new FilterPredicate(Event.EVENT_NAME, FilterOperator.EQUAL, req.getParameter(Event.EVENT_NAME).trim());
						query.setFilter(isEvent);
					    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (events.size() > 0) {
					    	if (events.size() > 1) System.out.println("Multiple events with name " + req.getParameter(Event.EVENT_NAME));
			    			
					    	if ((Boolean) events.get(0).getProperty(Event.ACTIVE_NAME)) resetNames(-1);
					    	int eID = ((Long) events.get(0).getProperty(Event.EVENT_ID)).intValue();
			    			datastore.delete(events.get(0).getKey());
			    			strResp = "Event '" + req.getParameter(Event.EVENT_NAME) + "' deleted.";
				    		if (curEvent == eID) {
				    			settings.get(0).setProperty(Settings.CUR_EVENT, -1);
							    datastore.put(settings.get(0));
							    curEvent = -1;
							    strResp = strResp + "&&" + Integer.toString(curEvent);
					    	}
					    } else {
					    	strResp = ERR_STR + " Event '" + req.getParameter(Event.EVENT_NAME) + "' was not found.";
					    }
					}
				} else if (type.equals(Settings.ENTITY_KIND)) {
					if (req.getParameter(Settings.ADMIN_NUM) != null) {
						if (!((String) req.getParameter(Settings.ADMIN_NUM)).equals("")) {
							settings.get(0).setProperty(Settings.ADMIN_NUM, req.getParameter(Settings.ADMIN_NUM));
						}
					}
					if (req.getParameter(Settings.SITE_NAME) != null) {
						if (!((String) req.getParameter(Settings.SITE_NAME)).equals("")) {
							settings.get(0).setProperty(Settings.SITE_NAME, req.getParameter(Settings.SITE_NAME));
						}
					}
					if (req.getParameter(Settings.CUR_EVENT) != null) {
						try {
							if (Integer.parseInt(req.getParameter(Settings.CUR_EVENT)) == -1) {
								settings.get(0).setProperty(Settings.CUR_EVENT, -1);
							} else {
								query = new Query(Event.ENTITY_KIND, new Event().getEventKey());
								Filter isEvent = new FilterPredicate(Event.EVENT_ID, FilterOperator.EQUAL, Integer.parseInt(req.getParameter(Settings.CUR_EVENT)));
								query.setFilter(isEvent);
							    List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
							    if (events.isEmpty()) {
							    	strResp = "err: Could not find event ID " + req.getParameter(Settings.CUR_EVENT);
							    } else {
							    	if (events.size() > 1) System.out.println("Multiple events with ID " + req.getParameter(Settings.CUR_EVENT));
							    	events.get(0).setProperty(Event.ARCHIVED_NAME, false);
							    	datastore.put(events.get(0));
							    	settings.get(0).setProperty(Settings.CUR_EVENT, Integer.parseInt(req.getParameter(Settings.CUR_EVENT)));
							    }
							}
						} catch (NumberFormatException e) {
							strResp = "err: Please format event ID as a number.";
						}
					}
					if (strResp.equals("")) {
						datastore.put(settings.get(0));
						strResp = "Settings updated.";
					}
				}
			}
		}
		
		resp.getOutputStream().println(strResp);
	}
    
    private void resetNames(int eID) {
    	ArrayList<String> playerNames = new ArrayList<String>();
    	DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    	Query query = new Query(Name.ENTITY_KIND, new Name().getNameKey());
    	Filter isName = new FilterPredicate(Name.USED, FilterOperator.EQUAL, true);
    	query.setFilter(isName);
	    if (eID > 0) {
	    	Query pquery = new Query(Player.ENTITY_KIND, new Player().getPlayerKey());
	    	Filter isEvent = new FilterPredicate(Player.EVENT_ID, FilterOperator.EQUAL, eID);
	    	pquery.setFilter(isEvent);
		    List<Entity> events = datastore.prepare(pquery).asList(FetchOptions.Builder.withDefaults());
		    for (Entity e: events) {
		    	playerNames.add((String) e.getProperty(Player.PLAYER_NAME));
		    }
		    if (!playerNames.isEmpty()) {
			    Filter newNames = new FilterPredicate(Name.NAME, FilterOperator.IN, playerNames);
			    query.setFilter(CompositeFilterOperator.or(isName,newNames));
		    }
	    }
	    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
	    for (Entity n : names) {
	    	n.setProperty(Name.USED, false);
	    	if (eID > 0) {
	    		if (playerNames.contains((String) n.getProperty(Name.NAME))) {
	    			n.setProperty(Name.USED, true);
	    		}
	    	}
	    }
	    datastore.put(names);
    }
    
    private void deactivateEvents() {
    	DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
    	Query query = new Query(Event.ENTITY_KIND, new Event().getEventKey()).addSort(Event.EVENT_ID, Query.SortDirection.DESCENDING);
	    Filter isActive = new FilterPredicate(Event.ACTIVE_NAME, FilterOperator.EQUAL, true);
	    query.setFilter(isActive);
    	List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
    	for (Entity e : events) {
    		e.setProperty(Event.ACTIVE_NAME, false);
    	}
    	datastore.put(events);
    }
}
