package com.csoft.clinelympics;

import java.io.IOException;
import javax.servlet.http.*;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

@SuppressWarnings("serial")
public class InboundServlet extends HttpServlet {
    
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		String smsid = req.getParameter("SmsSid");
		String accountid = req.getParameter("AccountSid");
		String number = req.getParameter("From");
		String body = req.getParameter("Body");
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		
		Key textKey = KeyFactory.createKey("Texts", "textList");
		Entity text = new Entity("text", textKey);
		text.setProperty("SmsSid", smsid);
		text.setProperty("AccountSid", accountid);
		text.setProperty("From", number);
		text.setProperty("Body", body);
		
		datastore.put(text);
		
		/*
		Key gameKey = KeyFactory.createKey("Games", "gameList");
		Entity game = new Entity("game", gameKey);
		game.setProperty("gameID", gameID);
		game.setProperty("gameName", gameName);
		game.setProperty("scoreType", scoreType);
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(game);
		*/
		
		resp.sendRedirect("/games.jsp");
	}
}
