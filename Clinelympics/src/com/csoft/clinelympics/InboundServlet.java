package com.csoft.clinelympics;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Date;
import java.util.List;
import java.util.Random;

import javax.servlet.http.*;
import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.FetchOptions;
import com.google.appengine.api.datastore.Query;
import com.google.appengine.api.datastore.Query.CompositeFilterOperator;
import com.google.appengine.api.datastore.Query.Filter;
import com.google.appengine.api.datastore.Query.FilterPredicate;
import com.google.appengine.api.datastore.Query.FilterOperator;

import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import org.w3c.dom.*;

@SuppressWarnings("serial")
public class InboundServlet extends HttpServlet {
	
	private static final String CMD_REG = "REGISTER";
	private static final String CMD_SCORE = "SCORE";
	private static final String CMD_WHO = "WHO";
	private static final String CMD_ADMIN = "ADMIN";
	private static final String CMD_CHANGE = "CHANGE";
	private static final String CMD_START = "START";
	private static final String CMD_STOP = "STOP";
	private static final String CMD_TEAM = "TEAM";
	private static final String CMD_NAME = "NAME";
	private static final String CMD_HELP = "HELP";
    
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		boolean isValid = true;
		boolean isActive = false;
		String smsresp = "";
		Text inText = new Text(req.getParameter(Text.smsIDName), 
				req.getParameter(Text.accountSIDName), 
				req.getParameter(Text.fromName), 
				req.getParameter(Text.bodyName));
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		
		datastore.put(inText.createEntity());
		
		Query query = new Query(Settings.entityKind, new Settings().getSettingsKey());
		List<Entity> settings = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		if (!settings.isEmpty()) {
			if (settings.size() > 1) System.out.println("Settings has mulitple entries.");
			int curEvent = ((Long) settings.get(0).getProperty(Settings.curEventName)).intValue();
			
			query = new Query(Event.entityKind, new Event().getEventKey());
			Filter feID = new FilterPredicate(Event.eventIDName, FilterOperator.EQUAL, curEvent);
			query.setFilter(feID);
			List<Entity> events = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
			
			String[] split = inText.getBody().split(" ");
			if (events.size() > 0) {
				if ((Boolean) events.get(0).getProperty(Event.activeName)) isActive = true;
				if (events.size() > 1) System.out.println("Multiple events with ID " + Integer.toString(curEvent));
				if (split[0].equalsIgnoreCase(CMD_REG)) {
					if (split.length >= 2) {
					    query = new Query(Player.entityKind, new Player().getPlayerKey());
						Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, inText.getFrom());
						query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
					    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (players.isEmpty()) {
							String teamName = inText.getBody().substring(inText.getBody().indexOf(" ")+1).trim().toUpperCase();
							Random r = new Random(System.currentTimeMillis());
							query = new Query(Name.entityKind, new Name().getNameKey());
							
							if (r.nextInt() > 0) {
								query.addSort(Name.rndStr, Query.SortDirection.ASCENDING);
							} else {
								query.addSort(Name.rndStr, Query.SortDirection.DESCENDING);
							}
							Filter notUsed = new FilterPredicate(Name.usedStr, FilterOperator.EQUAL, false);
						    query.setFilter(notUsed);
						    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(10));
						    int curEnt = r.nextInt(names.size());
						    String newName = (String) names.get(curEnt).getProperty(Name.nameStr);
						    
							Player player = new Player(inText.getFrom(), newName, teamName, curEvent);
							datastore.put(player.createEntity());
							names.get(curEnt).setProperty(Name.usedStr, true);
							datastore.put(names.get(curEnt));
							
							smsresp = "Welcome to team " + Player.humanize(teamName) + ", "  + newName;
					    }
					} else {
						isValid = false;
					}
				} else if (split[0].equalsIgnoreCase(CMD_SCORE)) {
					if (split.length == 3) {
						query = new Query(Player.entityKind, new Player().getPlayerKey());
						Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, inText.getFrom());
						query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
					    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (players.size() > 0) {
					    	try {
						    	if (players.size() > 1) System.out.println("Multiple players for player ID " + inText.getFrom());
						    	query = new Query(Game.entityKind, new Game().getGameKey());
								Filter isGame = new FilterPredicate(Game.gameIDName, FilterOperator.EQUAL, Integer.parseInt(split[1]));
								feID = new FilterPredicate(Score.eventIDName, FilterOperator.EQUAL, curEvent);
								query.setFilter(CompositeFilterOperator.and(isGame, feID));
							    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
							    if (games.size() > 0) {
							    	if (games.size() > 1) System.out.println("Multiple games found for game " + split[1]);
									query = new Query(Score.entityKind, new Score().getScoreKey());
									query.addSort(Score.dateName, Query.SortDirection.DESCENDING);
									Filter fpID = new FilterPredicate(Score.playerIDName, FilterOperator.EQUAL, inText.getFrom());
									Filter fgID = new FilterPredicate(Score.gameIDName, FilterOperator.EQUAL, Integer.parseInt(split[1]));
									query.setFilter(CompositeFilterOperator.and(fpID,fgID,feID));
									List<Entity> scores = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
									if (scores.size() == 0) {
										Score score = new Score(inText.getFrom(), Integer.parseInt(split[1]), Integer.parseInt(split[2]), curEvent);
										datastore.put(score.createEntity());
									} else {
										scores.get(0).setProperty(Score.playerScoreName, Integer.parseInt(split[2]));
										scores.get(0).setProperty(Score.dateName, new Date());
										datastore.put(scores.get(0));
										if (scores.size() > 1) {
											System.out.println("Multiple scores for player " + inText.getFrom() + " and game " + split[1]);
										}
									}
							    } else {
							    	smsresp = "Couldn't find that game ID.";
							    }
						    } catch (NumberFormatException e) {
						    	smsresp = "Please ensure gameID and score are numbers.";
						    }
					    } else {
					    	smsresp = "Could not find you as a player. Have you registered yet?";
					    }
					} else {
						isValid = false;
					}
				} else if (split[0].equalsIgnoreCase(CMD_WHO)) {
					// return player name
					query = new Query(Player.entityKind, new Player().getPlayerKey());
					Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, inText.getFrom());
					query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
				    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
				    if (players.size() == 1) {
				    	smsresp = "You are " + (String) players.get(0).getProperty(Player.playerNameName);
				    } else {
				    	if (players.size() > 1) System.out.println("Multiple who answers for player with ID " + inText.getFrom());
				    	smsresp = "You could not be found. Have you registered yet?";
				    }
				} else if (split[0].equalsIgnoreCase(CMD_CHANGE)) {
					if (split[1].equalsIgnoreCase(CMD_TEAM)) {
						query = new Query(Player.entityKind, new Player().getPlayerKey());
						Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, inText.getFrom());
						query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
					    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (players.size() == 1) {
					    	String teamName = inText.getBody().substring(inText.getBody().toUpperCase().indexOf(CMD_TEAM)+5).trim().toUpperCase();
					    	players.get(0).setProperty(Player.teamNameName, teamName);
					    	datastore.put(players.get(0));
					    	smsresp = "You have been changed to team " + Player.humanize(teamName);
					    } else {
					    	if (players.size() > 1) System.out.println("Multiple players with ID " + inText.getFrom());
					    	smsresp = "We ran into an error.";
					    }
					} else if (split[1].equalsIgnoreCase(CMD_NAME)) {
						query = new Query(Player.entityKind, new Player().getPlayerKey());
						Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, inText.getFrom());
						query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
					    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (players.size() == 1) {
					    	String oldName = (String) players.get(0).getProperty(Player.playerNameName);
					    	Random r = new Random(System.currentTimeMillis());
							query = new Query(Name.entityKind, new Name().getNameKey());
							
							if (r.nextInt() > 0) {
								query.addSort(Name.rndStr, Query.SortDirection.ASCENDING);
							} else {
								query.addSort(Name.rndStr, Query.SortDirection.DESCENDING);
							}
							Filter notUsed = new FilterPredicate(Name.usedStr, FilterOperator.EQUAL, false);
						    query.setFilter(notUsed);
						    List<Entity> names = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(10));
						    int curEnt = r.nextInt(names.size());
						    String newName = (String) names.get(curEnt).getProperty(Name.nameStr);
						    players.get(0).setProperty(Player.playerNameName, newName);
							datastore.put(players.get(0));
							
							smsresp = "Your new name is " + newName;
							
							names.get(curEnt).setProperty(Name.usedStr, true);
							datastore.put(names.get(curEnt));
							
							query = new Query(Name.entityKind, new Name().getNameKey());
							
							Filter isOldName = new FilterPredicate(Name.nameStr, FilterOperator.EQUAL, oldName);
						    query.setFilter(isOldName);
						    names = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(10));
						    if (names.size() == 1) {
						    	names.get(0).setProperty(Name.usedStr, false);
						    	datastore.put(names.get(0));
						    } else {
						    	if (names.size() > 1) System.out.println("Multiple names for " + oldName);
						    	smsresp = "We ran into an error.";
						    }
					    } else {
					    	if (players.size() > 1) System.out.println("Multiple players with ID " + inText.getFrom());
					    	smsresp = "We ran into an error.";
					    }
					} else {
						isValid = false;
					}
				} else if (split[0].equalsIgnoreCase(CMD_HELP)) {
					if (split.length > 1) {
						if (split[1].equalsIgnoreCase(CMD_REG)) {
							smsresp = "Register as a player. Usage: REGISTER <team name>";
						} else if (split[1].equalsIgnoreCase(CMD_SCORE)) {
							smsresp = "Enter your score for a game. Usage: SCORE <game id> <score>";
						} else if (split[1].equalsIgnoreCase(CMD_WHO)) {
							smsresp = "Tells you your name. Usage: WHO";
						} else if (split[1].equalsIgnoreCase(CMD_CHANGE)) {
							smsresp = "Either change names or change teams. Usage: CHANGE TEAM <team name> // CHANGE NAME";
						} else { 
							smsresp = "Available commands: " + CMD_REG + ", " + CMD_SCORE + ", " + CMD_WHO + ", " + CMD_CHANGE + ", " + CMD_HELP;
						}
					} else {
						smsresp = "Available commands: " + CMD_REG + ", " + CMD_SCORE + ", " + CMD_WHO + ", " + CMD_CHANGE + ", " + CMD_HELP;
					}
				} else if (split[0].equalsIgnoreCase(CMD_ADMIN)) {
					isValid = true;
				} else {
					isValid = false;
				}
				
				if (!isValid) {
					smsresp = "I didn't understand. Text HELP for a list of available commands.";
				}
			}
			if (split[0].equalsIgnoreCase(CMD_ADMIN)) {
				if (inText.getFrom().equalsIgnoreCase((String) settings.get(0).getProperty(Settings.adminNumName))) {
					if (split[1].equalsIgnoreCase(CMD_START)) {
						if (inText.getBody().length() == (CMD_ADMIN.length() + CMD_START.length() + 1)) {
							if (isActive) {
								smsresp = "Event " + curEvent + " is already active.";
							} else {
								if (((Long) settings.get(0).getProperty(Settings.curEventName)).intValue() == -1) {
									smsresp = "Please specify an event, ie ADMIN START 1";
								} else {
									query = new Query(Event.entityKind, new Event().getEventKey()).addSort(Event.eventIDName, Query.SortDirection.DESCENDING);
								    Filter activeEvents = new FilterPredicate(Event.activeName, FilterOperator.EQUAL, true);
								    query.setFilter(activeEvents);
							    	List<Entity> es = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
							    	for (Entity e : es) {
							    		e.setProperty(Event.activeName, false);
							    	}
							    	datastore.put(es);
							    	events.get(0).setProperty(Event.activeName, true);
							    	datastore.put(events.get(0));
							    	isActive = true;
							    	smsresp = "Event " + curEvent + " has been started.";
								}
							}
						} else {
							try {
								int eventID = Integer.parseInt(split[2]);
								boolean eIsActive = false;
								query = new Query(Event.entityKind, new Event().getEventKey());
							    Filter activeEvents = new FilterPredicate(Event.activeName, FilterOperator.EQUAL, true);
							    query.setFilter(activeEvents);
						    	List<Entity> es = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
						    	for (Entity e : es) {
						    		e.setProperty(Event.activeName, false);
						    		if (((Long) e.getProperty(Event.eventIDName)).intValue() == eventID) eIsActive = true;
						    	}
						    	if (eIsActive) {
						    		smsresp = "Event " + eventID + " is already active.";
						    	} else {
						    		datastore.put(es);
						    		query = new Query(Event.entityKind, new Event().getEventKey());
								    Filter iseID = new FilterPredicate(Event.eventIDName, FilterOperator.EQUAL, eventID);
								    query.setFilter(iseID);
							    	es = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
							    	if (es.size() > 1) System.out.println("Multiple events with ID " + eventID);
							    	es.get(0).setProperty(Event.activeName, true);
							    	settings.get(0).setProperty(Settings.curEventName, eventID);
							    	datastore.put(es.get(0));
							    	datastore.put(settings.get(0));
							    	isActive = true;
							    	smsresp = "Event " + eventID + " has been started.";
						    	}
							} catch (NumberFormatException e) {
								smsresp = "I could not understand your event. Try using a number.";
							}
						}
					} else if (split[1].equalsIgnoreCase(CMD_STOP)) {
						if (!isActive) {
							smsresp = "Event " + curEvent + " is not currently active.";
						} else {
							query = new Query(Event.entityKind, new Event().getEventKey());
						    Filter iseID = new FilterPredicate(Event.eventIDName, FilterOperator.EQUAL, curEvent);
						    query.setFilter(iseID);
					    	List<Entity> es = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    	if (es.size() > 1) System.out.println("Multiple events with ID " + curEvent);
					    	es.get(0).setProperty(Event.activeName, false);
					    	settings.get(0).setProperty(Settings.curEventName, -1);
					    	datastore.put(es.get(0));
					    	datastore.put(settings.get(0));
					    	isActive = false;
					    	smsresp = "Event " + curEvent + " has been stopped.";
						}
					} else {
						isValid = false;
					}
				}
			}
		}
		
		resp.setContentType("text/xml");
		resp.setCharacterEncoding("UTF-8");
		PrintWriter sos = resp.getWriter();
		
		Document dom;
	    DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
	    try {
	        DocumentBuilder db = dbf.newDocumentBuilder();
	        dom = db.newDocument();

	        Element rootEle = dom.createElement("Response");
	        
			if (!smsresp.equals("")) {
		        Element e = dom.createElement("Sms");
		        e.appendChild(dom.createTextNode(smsresp));
		        rootEle.appendChild(e);
			}

	        dom.appendChild(rootEle);

	        try {
	            Transformer tr = TransformerFactory.newInstance().newTransformer();
	            tr.setOutputProperty(OutputKeys.INDENT, "yes");
	            tr.setOutputProperty(OutputKeys.METHOD, "xml");
	            tr.setOutputProperty(OutputKeys.ENCODING, "UTF-8");

	            tr.transform(new DOMSource(dom), 
	                                 new StreamResult(sos));

	        } catch (TransformerException te) {
	            System.out.println(te.getMessage());
	        }
	    } catch (ParserConfigurationException pce) {
	        System.out.println(pce.getMessage());
	    }
	}
}
