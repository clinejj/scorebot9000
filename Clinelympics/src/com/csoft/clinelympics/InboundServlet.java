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
	
	private static final String cmdReg = "REGISTER";
	private static final String cmdScore = "SCORE";
	private static final String cmdWho = "WHO";
	private static final String cmdAdmin = "ADMIN";
	private static final String cmdHelp = "HELP";
    
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
				isActive = true;
				if (events.size() > 1) System.out.println("Multiple events with ID " + Integer.toString(curEvent));
				if (split[0].equalsIgnoreCase(cmdReg)) {
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
							
							smsresp = "Welcome to team " + teamName + ", "  + newName;
					    }
					} else {
						isValid = false;
					}
				} else if (split[0].equalsIgnoreCase(cmdScore)) {
					if (split.length == 3) {
						query = new Query(Player.entityKind, new Player().getPlayerKey());
						Filter isPlayer = new FilterPredicate(Player.playerIDName, FilterOperator.EQUAL, inText.getFrom());
						query.setFilter(CompositeFilterOperator.and(isPlayer,feID));
					    List<Entity> players = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
					    if (players.size() > 0) {
					    	if (players.size() > 1) System.out.println("Multiple players for player ID " + inText.getFrom());
					    	query = new Query(Game.entityKind, new Game().getGameKey());
							Filter isGame = new FilterPredicate(Game.gameIDName, FilterOperator.EQUAL, Integer.parseInt(split[1]));
							query.setFilter(isGame);
						    List<Entity> games = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
						    if (games.size() > 0) {
						    	if (games.size() > 1) System.out.println("Multiple games found for game " + split[1]);
								query = new Query(Score.entityKind, new Score().getScoreKey());
								query.addSort(Score.dateName, Query.SortDirection.DESCENDING);
								Filter fpID = new FilterPredicate(Score.playerIDName, FilterOperator.EQUAL, inText.getFrom());
								Filter fgID = new FilterPredicate(Score.gameIDName, FilterOperator.EQUAL, Integer.parseInt(split[1]));
								feID = new FilterPredicate(Score.eventIDName, FilterOperator.EQUAL, curEvent);
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
					    } else {
					    	smsresp = "Could not find you as a player. Have you registered yet?";
					    }
					} else {
						isValid = false;
					}
				} else if (split[0].equalsIgnoreCase(cmdWho)) {
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
				} else if (split[0].equalsIgnoreCase(cmdHelp)) {
					isValid = true;
					smsresp = "Available commands: " + cmdReg + ", " + cmdScore + ", " + cmdWho + ", " + cmdHelp;
				} else {
					isValid = false;
				}
				
				if (!isValid) {
					smsresp = "I didn't understand. Text HELP for a list of available commands.";
				}
			}
			if (split[0].equalsIgnoreCase(cmdAdmin)) {
				if (inText.getFrom().equalsIgnoreCase((String) settings.get(0).getProperty(Settings.adminNumName))) {
					smsresp = "admin valid";
					if (isActive) {
						smsresp = "admin valid and event active";
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
