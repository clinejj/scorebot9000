package com.csoft.clinelympics;

import java.io.IOException;
import javax.servlet.http.*;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

@SuppressWarnings("serial")
public class RegisterServlet extends HttpServlet {
	
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		String playerID = req.getParameter("playerID");
		String playerName = req.getParameter("playerName").trim();
		String teamName = req.getParameter("teamName").trim();
		
		Key playerKey = KeyFactory.createKey("Players", "playerList");
		Entity player = new Entity("player", playerKey);
		player.setProperty("playerID", playerID);
		player.setProperty("playerName", playerName);
		player.setProperty("teamName", teamName);
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(player);
		
		resp.sendRedirect("/players.jsp");
	}
}
